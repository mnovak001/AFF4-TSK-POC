#pragma once
#include <tsk/libtsk.h>

#ifdef __cplusplus
extern "C" {
#endif

TSK_IMG_INFO* aff4_open_image(const char* path);
void aff4_close_image(TSK_IMG_INFO* img);

#ifdef __cplusplus
}
#endif
