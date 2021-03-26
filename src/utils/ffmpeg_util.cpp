#include "ffmpeg_util.h"
#include <cstring>
#include <QtDebug>

const int ALIGN_SIZE = 1;

uint8_t *FFmpegUtil::avMalloc(int size) {
    return (uint8_t *)av_malloc(size);
}

void FFmpegUtil::avFree(void *ptr) {
    av_free(ptr);
}

int FFmpegUtil::getFormatSize(enum AVPixelFormat fmt, int width, int height) {
    return av_image_get_buffer_size(fmt, width, height, ALIGN_SIZE);
}

AVFrame *FFmpegUtil::requestFrame(enum AVPixelFormat fmt, int width, int height) {
    return nullptr;
}

uint8_t *FFmpegUtil::resizeBGRAImage(uint8_t *the_np, int from_width, int from_height, int to_width, int to_height) {
    SwsContext *resize = sws_getContext(from_width, from_height, AV_PIX_FMT_BGRA, to_width, to_height, AV_PIX_FMT_BGRA, SWS_BICUBIC, NULL, NULL, NULL);

    // 初始化源图像信息
    uint8_t* from_frame_data[] = { the_np };
    int srcStride[4];
    av_image_fill_linesizes(srcStride, AV_PIX_FMT_BGRA, from_width);

    // 初始化目标图像信息
    int to_size = FFmpegUtil::getFormatSize(AV_PIX_FMT_BGRA, to_width, to_height);
    uint8_t *resize_np = FFmpegUtil::avMalloc(to_size);
    uint8_t* to_frame_data[] = { resize_np };
    int dstStride[4];
    av_image_fill_linesizes(dstStride, AV_PIX_FMT_BGRA, to_width);

    sws_scale(resize, from_frame_data, srcStride, 0, from_height, to_frame_data, dstStride);
    sws_freeContext(resize);

    return resize_np;
//    av_image_fill_arrays(to_frame->data, to_frame->linesize, resize_np, AV_PIX_FMT_BGRA, to_width, to_height, ALIGN_SIZE);
}

uint8_t *FFmpegUtil::imageYUYV2BGRA(uint8_t *the_np, int width, int height) {
    SwsContext *resize = sws_getContext(width, height, AV_PIX_FMT_YUYV422, width, height, AV_PIX_FMT_BGRA, SWS_BICUBIC, NULL, NULL, NULL);

    // 初始化源图像信息
    int srcStride[4];
    av_image_fill_linesizes(srcStride, AV_PIX_FMT_YUYV422, width);
    AVFrame *from_frame = av_frame_alloc();
    av_image_fill_arrays(from_frame->data, srcStride, the_np, AV_PIX_FMT_YUYV422, width, height, ALIGN_SIZE);

    // 初始化目标图像信息
    int to_size = FFmpegUtil::getFormatSize(AV_PIX_FMT_BGRA, width, height);
    uint8_t *ans_np = FFmpegUtil::avMalloc(to_size);
    uint8_t* to_frame_data[] = { ans_np };
    int dstStride[4];
    av_image_fill_linesizes(dstStride, AV_PIX_FMT_BGRA, width);

    sws_scale(resize, from_frame->data, srcStride, 0, height, to_frame_data, dstStride);
    sws_freeContext(resize);
    FFmpegUtil::avFree(from_frame);

    return ans_np;
}

AVFrame *FFmpegUtil::getAVFrameBGRA(uint8_t *the_np, int width, int height) {
    AVFrame *frame = av_frame_alloc();

    //这里FFmpeg会帮我们计算这个格式的图片，需要多少字节来存储
    //相当于前一篇博文例子中的width * height * 2
//    int bytes_num = avpicture_get_size(AV_PIX_FMT_YUV420P, width, height); //AV_PIX_FMT_YUV420P是FFmpeg定义的标明YUV420P图像格式的宏定义

    //申请空间来存放图片数据。包含源数据和目标数据
//    uint8_t* buff = (uint8_t*)av_malloc(bytes_num);

    //前面的av_frame_alloc函数，只是为这个AVFrame结构体分配了内存，
    //而该类型的指针指向的内存还没分配。这里把av_malloc得到的内存和AVFrame关联起来。
    //当然，其还会设置AVFrame的其他成员
//    avpicture_fill((AVPicture*)frame, the_np, AV_PIX_FMT_BGRA, width, height);
    av_image_fill_arrays(frame->data, frame->linesize, the_np, AV_PIX_FMT_BGRA, width, height, ALIGN_SIZE);
    return frame;
}

// dist_np: 目标图像
// d_width: 目标图像总宽度
// d_height: 目标图像总高度 // 不需要
// to_left: 目标图像赋值x位置
// to_top: 目标图像赋值y位置
// source_np: 源图像
// s_width: 源图像宽度
// s_height: 源图像高度 // 不需要
// pos_left: 源图像截取开始x位置
// pos_top: 源图像截取开始y位置
// pos_width: 源图像截取width
// pos_height: 源图像截取height
void FFmpegUtil::combineBGRAImage(uint8_t *dist_np, int d_width, int to_left, int to_top, uint8_t *source_np, int s_width, int pos_left, int pos_top, int pos_width, int pos_height) {
    int channels = 4;
    for (int row = 0; row < pos_height; row++) {
        int dist_index_start = ((to_top+row)*d_width+to_left)*channels;
        int source_index_start = ((pos_top+row)*s_width+pos_left)*channels;
        int copy_count = pos_width*channels;
        memcpy(dist_np+dist_index_start, source_np+source_index_start, copy_count);
    }
}

uint8_t *FFmpegUtil::copyImage(QImage &image) {
    uint8_t * the_image_np = image.bits();
    int byte_count = image.sizeInBytes();
    uint8_t *ans = FFmpegUtil::avMalloc(byte_count);
    memcpy(ans, the_image_np, byte_count);
    return ans;
}
