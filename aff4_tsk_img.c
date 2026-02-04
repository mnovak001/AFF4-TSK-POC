#include "aff4_tsk_img.h"

#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "aff4/aff4-c.h"

#ifndef AFF4_TSK_AFF4_MAPPING_SET

#include "aff4/aff4-c.h"

/* --- TYPE: handle --- */
typedef int AFF4H;

/* Open AFF4 container and return handle to FIRST image */
static AFF4H aff4_open_first_image(const char* path)
{
    /* aff4-cpp-lite opens the first image implicitly */
    return AFF4_open(path);
}

/* Positional read */
static int aff4_read_at(
    AFF4H h,
    uint64_t off,
    uint8_t* buf,
    size_t len,
    size_t* out_read)
{
    if (!h || !buf)
        return -1;

    ssize_t r = AFF4_read(h, off, buf, len);
    if (r < 0)
        return -1;

    if (out_read)
        *out_read = (size_t)r;

    return 0;
}

/* Logical image size */
static uint64_t aff4_get_size(AFF4H h)
{
    if (!h)
        return 0;

    return AFF4_object_size(h);
}

/* Close AFF4 handle */
static void aff4_close_handle(AFF4H h)
{
    if (h)
        AFF4_close(h);
}

#endif /* AFF4_TSK_AFF4_MAPPING_SET */

typedef struct {
    TSK_IMG_INFO img;      /* MUST be first */
    AFF4H h;               /* AFF4 handle */
    uint64_t size;         /* cached image size */
    pthread_mutex_t m;     /* serialize reads */
} AFF4_TSK_IMG;

/* Error helper (matches older TSK) */
static void set_tsk_err(uint32_t code, const char* msg)
{
    tsk_error_set_errno(code);
    tsk_error_set_errstr("%s", msg);
}

/* -------- read callback -------- */
static ssize_t aff4_tsk_read(
    TSK_IMG_INFO* img,
    TSK_OFF_T offset,
    char* buf,
    size_t len)
{
    AFF4_TSK_IMG* self = (AFF4_TSK_IMG*)img;

    if (!buf) {
        set_tsk_err(TSK_ERR_IMG_READ, "NULL buffer");
        return -1;
    }

    if (offset < 0)
        return 0;

    uint64_t off = (uint64_t)offset;
    if (off >= self->size)
        return 0;

    size_t to_read = len;
    if (off + to_read > self->size)
        to_read = (size_t)(self->size - off);

    pthread_mutex_lock(&self->m);

    size_t got = 0;
    int rc = aff4_read_at(
        self->h,
        off,
        (uint8_t*)buf,
        to_read,
        &got);

    pthread_mutex_unlock(&self->m);

    if (rc != 0) {
        set_tsk_err(TSK_ERR_IMG_READ, "AFF4 read failed");
        return -1;
    }

    return (ssize_t)got;
}

/* -------- close callback -------- */
static void aff4_tsk_close_cb(TSK_IMG_INFO* img)
{
    AFF4_TSK_IMG* self = (AFF4_TSK_IMG*)img;

    if (self->h) {
        aff4_close_handle(self->h);
        self->h = NULL;
    }

    pthread_mutex_destroy(&self->m);
    free(self);
}

/* -------- factory -------- */
TSK_IMG_INFO* aff4_tsk_img_open(const char* aff4_path)
{
    if (!aff4_path || !*aff4_path) {
        set_tsk_err(TSK_ERR_IMG_OPEN, "Empty AFF4 path");
        return NULL;
    }

    AFF4_TSK_IMG* self =
        (AFF4_TSK_IMG*)calloc(1, sizeof(AFF4_TSK_IMG));

    if (!self) {
        set_tsk_err(TSK_ERR_AUX_MALLOC, "Out of memory");
        return NULL;
    }

    memset(&self->img, 0, sizeof(self->img));

    if (pthread_mutex_init(&self->m, NULL) != 0) {
        set_tsk_err(TSK_ERR_AUX_MALLOC, "Mutex init failed");
        free(self);
        return NULL;
    }

    self->h = aff4_open_first_image(aff4_path);
    if (!self->h) {
        set_tsk_err(TSK_ERR_IMG_OPEN, "Failed to open AFF4 image");
        pthread_mutex_destroy(&self->m);
        free(self);
        return NULL;
    }

    self->size = aff4_get_size(self->h);
    if (self->size == 0) {
        set_tsk_err(TSK_ERR_IMG_OPEN, "AFF4 image size is 0");
        aff4_close_handle(self->h);
        pthread_mutex_destroy(&self->m);
        free(self);
        return NULL;
    }

    /* ---- TSK_IMG_INFO init (OLDER TSK ABI) ---- */
    self->img.itype = TSK_IMG_TYPE_EXTERNAL;
    self->img.size = self->size;
    self->img.sector_size = 512;
    self->img.read = aff4_tsk_read;
    self->img.close = aff4_tsk_close_cb;

    return &self->img;
}

void aff4_tsk_img_close(TSK_IMG_INFO* img)
{
    if (img && img->close)
        img->close(img);
}
