#include "window_grabber.h"
#include "src/utils/ffmpeg_util.h"
#include "src/window_capture/window_capture.h"
#include <cstring>
#include <QMutex>
#include <QMutexLocker>
#include <QTime>
#include <QtDebug>

WindowGrabber::WindowGrabber(WindowGrabberOptions options) {
    this->options = options;
    this->run_mutex = new QMutex();
    this->frame_mutex = new QMutex();
    this->current_np.bits = nullptr;
}

WindowGrabber::~WindowGrabber() {
    delete this->run_mutex;
    delete this->frame_mutex;
    if (this->current_np.bits) {
        FFmpegUtil::avFree(this->current_np.bits);
    }
}

WindowGrabberInfo WindowGrabber::getFrame() {
    QMutexLocker locker(this->frame_mutex);
    int width = this->current_np.width;
    int height = this->current_np.height;
    int channels = this->current_np.channels;
    WindowGrabberInfo ans = this->current_np;
    int bit_size = width*height*channels;
    if (this->current_np.bits) {
        uint8_t* bits = FFmpegUtil::avMalloc(bit_size);
        memcpy(bits, this->current_np.bits, bit_size);
        ans.bits = bits;
    }
    else {
        ans.bits = nullptr;
    }
    return ans;
}

void WindowGrabber::run() {
    this->run_mutex->lock();
    this->stoped = false;
    this->run_mutex->unlock();

    while (true) {
        this->run_mutex->lock();
        if (this->stoped) {
            this->run_mutex->unlock();
            break;
        }
        this->run_mutex->unlock();

        QTime frame_start_time = QTime::currentTime();

        int frame_type = this->options.frame_type;
        double frame_rate = this->options.frame_rate;
        HWND hwnd = this->options.hwnd;
        WindowGrabberInfo ans_info;
//        qDebug() << "grabber before switch";
        switch (frame_type) {
            case FrameType::WINDOW: {
                CaptureWindowOptions options;
                options.enable_cursor = true;
                CaptureWindowResult result = WindowCapture::CaptureWindw(hwnd, options);
                ans_info.bits = result.bits;
                ans_info.width = result.width;
                ans_info.height = result.height;
                ans_info.channels = result.channels;
                break;
            }
            case FrameType::DESKTOP: {
                CaptureWindowOptions options;
                options.enable_cursor = true;
                options.force_cursor = true;
                CaptureWindowResult result = WindowCapture::CaptureWindw(hwnd, options);
                ans_info.bits = result.bits;
                ans_info.width = result.width;
                ans_info.height = result.height;
                ans_info.channels = result.channels;
                break;
            }
        }
//        qDebug() << "grabber after switch";
        WindowGrabberInfo old_info = this->current_np;
        this->frame_mutex->lock();
        this->current_np = ans_info;
        this->frame_mutex->unlock();
        FFmpegUtil::avFree(old_info.bits);
        old_info.bits = nullptr;
//        qDebug() << "grabber after free";

        QTime frame_end_time = QTime::currentTime();
        int ms_diff = frame_start_time.msecsTo(frame_end_time);
        int next_frame_time = int(1000.0/frame_rate-ms_diff);
        if (next_frame_time > 0) {
            this->msleep(next_frame_time);
        }
    }
}

void WindowGrabber::stop() {
    QMutexLocker locker(this->run_mutex);
    this->stoped = true;
}

bool WindowGrabber::isStoped() {
    QMutexLocker locker(this->run_mutex);
    return this->stoped;
}
