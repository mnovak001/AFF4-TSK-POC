#include <stdio.h>
#include <inttypes.h>
#include <tsk/libtsk.h>
#include "aff4_tsk_img.h"

static void print_tsk_err(const char* where) {
    fprintf(stderr, "\n[TSK ERROR] %s\n", where);
    tsk_error_print(stderr);
    tsk_error_reset();
}

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <image.aff4>\n", argv[0]);
        return 2;
    }

    const char* path = argv[1];

    TSK_IMG_INFO* img = aff4_tsk_img_open(path);
    if (!img) {
        print_tsk_err("aff4_tsk_img_open failed");
        return 1;
    }

    // 1) Detect volume system (partition table)
    TSK_VS_INFO* vs = tsk_vs_open(img, 0, TSK_VS_TYPE_DETECT);
    if (!vs) {
        // If there's NO partition table, then filesystem might be at offset 0
        print_tsk_err("tsk_vs_open (partition detect) failed; trying FS at offset 0");

        TSK_FS_INFO* fs0 = tsk_fs_open_img(img, 0, TSK_FS_TYPE_DETECT);
        if (!fs0) {
            print_tsk_err("tsk_fs_open_img at offset 0 failed");
            tsk_img_close(img);
            return 1;
        }

        printf("Opened filesystem at offset 0 successfully!\n");
        tsk_fs_close(fs0);
        tsk_img_close(img);
        return 0;
    }

    printf("Volume system detected: %s\n", tsk_vs_type_toname(vs->vstype));

    // 2) Iterate partitions
    const TSK_VS_PART_INFO* part = vs->part_list;
    int opened_any = 0;

    for (; part; part = part->next) {
        // Skip metadata / unallocated partitions
        if ((part->flags & TSK_VS_PART_FLAG_ALLOC) == 0)
            continue;

        uint64_t byte_off = part->start * (uint64_t)img->sector_size;

        printf("Partition: start=%" PRIu64 " len=%" PRIu64 " desc=%s\n",
               (uint64_t)part->start,
               (uint64_t)part->len,
               part->desc ? part->desc : "(none)");

        // 3) Try to open FS at partition offset
        TSK_FS_INFO* fs = tsk_fs_open_img(img, (TSK_OFF_T)byte_off, TSK_FS_TYPE_DETECT);
        if (fs) {
            printf("  -> Opened filesystem: %s at byte offset %" PRIu64 "\n",
                   tsk_fs_type_toname(fs->ftype), byte_off);
            opened_any = 1;

            // You can now do fls-like traversal with fs
            tsk_fs_close(fs);

            // If you only care about the first filesystem, break:
            break;
        } else {
            // Not necessarily an error—could be swap/unknown/etc.
            tsk_error_reset();
        }
    }

    if (!opened_any) {
        print_tsk_err("No filesystem opened from any allocated partition");
        tsk_vs_close(vs);
        tsk_img_close(img);
        return 1;
    }

    tsk_vs_close(vs);
    tsk_img_close(img);
    return 0;
}
