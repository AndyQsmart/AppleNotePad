#ifndef FFMPEGUTIL_H
#define FFMPEGUTIL_H

#include <stdint.h>
#include <QImage>
extern "C" {
    #include "libavcodec/avcodec.h"
    #include "libswscale/swscale.h"
    #include "libavutil/imgutils.h"
    #include "libavutil/frame.h"
    #include "libavutil/mem.h"
}

class FFmpegUtil {
public:
    static uint8_t *avMalloc(int size);
    static void avFree(void *ptr);
    static int getFormatSize(enum AVPixelFormat fmt, int width, int height);
    static AVFrame *requestFrame(enum AVPixelFormat fmt, int width, int height);
    static uint8_t *resizeBGRAImage(uint8_t *the_np, int from_width, int from_height, int to_width, int to_height);
    static uint8_t *imageYUYV2BGRA(uint8_t *the_np, int width, int height);
    static uint8_t *copyImage(QImage &image);
    static AVFrame *getAVFrameBGRA(uint8_t *the_np, int width, int height);
    static void combineBGRAImage(uint8_t *dist_np, int d_width, int to_left, int to_top, uint8_t *source_np, int s_width, int pos_left, int pos_top, int pos_width, int pos_height);
};

#endif // FFMPEGUTIL_H
