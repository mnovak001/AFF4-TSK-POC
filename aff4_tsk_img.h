#pragma once

#include <tsk/libtsk.h>

#ifdef __cplusplus
extern "C" {
#endif

TSK_IMG_INFO* aff4_tsk_img_open(const char* path);
void aff4_tsk_img_close(TSK_IMG_INFO* img);

#ifdef __cplusplus
}
#endif
