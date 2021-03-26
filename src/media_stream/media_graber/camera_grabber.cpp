#include "camera_grabber.h"
#include "src/utils/ffmpeg_util.h"
#include <QCamera>
#include <QCameraViewfinderSettings>
#include <QSize>
#include <QtDebug>

CameraFrameGrabberSurface::CameraFrameGrabberSurface(QObject *parent) : QAbstractVideoSurface(parent) {

}

QList<QVideoFrame::PixelFormat> CameraFrameGrabberSurface::supportedPixelFormats(QAbstractVideoBuffer::HandleType type) const {
    return QList<QVideoFrame::PixelFormat>() << QVideoFrame::Format_ARGB32
        << QVideoFrame::Format_ARGB32_Premultiplied << QVideoFrame::Format_RGB32
        << QVideoFrame::Format_RGB24 << QVideoFrame::Format_RGB565
        << QVideoFrame::Format_RGB555 << QVideoFrame::Format_ARGB8565_Premultiplied
        << QVideoFrame::Format_BGRA32 << QVideoFrame::Format_BGRA32_Premultiplied
        << QVideoFrame::Format_BGR32 << QVideoFrame::Format_BGR24
        << QVideoFrame::Format_BGR565 << QVideoFrame::Format_BGR555
        << QVideoFrame::Format_BGRA5658_Premultiplied << QVideoFrame::Format_AYUV444
        << QVideoFrame::Format_AYUV444_Premultiplied << QVideoFrame::Format_YUV444
        << QVideoFrame::Format_YUV420P << QVideoFrame::Format_YV12
        << QVideoFrame::Format_UYVY << QVideoFrame::Format_YUYV
        << QVideoFrame::Format_NV12 << QVideoFrame::Format_NV21
        << QVideoFrame::Format_IMC1 << QVideoFrame::Format_IMC2
        << QVideoFrame::Format_IMC3 << QVideoFrame::Format_IMC4
        << QVideoFrame::Format_Y8 << QVideoFrame::Format_Y16
        << QVideoFrame::Format_Jpeg << QVideoFrame::Format_CameraRaw
        << QVideoFrame::Format_AdobeDng;
}

bool CameraFrameGrabberSurface::present(const QVideoFrame &frame) {
    if (frame.isValid()) {
        this->current_frame = frame;
        return true;
    }
    return false;
}

QVideoFrame CameraFrameGrabberSurface::getCurrentFrame() {
    return this->current_frame;
}

CameraGrabber::CameraGrabber(CameraGrabberOptions options) {
    if (options.device_name.isEmpty()) {
        this->camera = new QCamera();
    }
    else {
        this->camera = new QCamera(options.device_name);
    }
    this->grabber = new CameraFrameGrabberSurface();
    this->camera->setViewfinder(this->grabber);
    this->options = options;
}

CameraGrabber::~CameraGrabber() {
    this->camera->stop();
    delete this->camera;
    delete this->grabber;
}

void CameraGrabber::start() {
    this->stoped = false;
    this->camera->start();
    this->autoSetSetting(this->options, true);
}

void CameraGrabber::stop() {
    this->stoped = true;
    this->camera->stop();
}

bool CameraGrabber::isStoped() {
    return this->stoped;
}

void CameraGrabber::autoSetSetting(CameraGrabberOptions &options, bool force_set) {
    if (force_set || (this->options.width != options.width || this->options.height != options.height)) {
        int width = options.width;
        int height = options.height;
        if (width && height) {
            QList<QSize> resolution_list = this->camera->supportedViewfinderResolutions();
            int resolution_list_length = resolution_list.length();
            int min_delta = width*height;
            QSize ans_resolution(0, 0);
            for (int i = 0; i < resolution_list_length; i++) {
                QSize *the_resolution = &(resolution_list[i]);
                int the_delta = abs(the_resolution->width()*the_resolution->height()-width*height);
                if (the_delta < min_delta) {
                    min_delta = the_delta;
                    ans_resolution = *the_resolution;
                }
            }
            qDebug() << "(camera_grabber.cpp)autoSetSetting:resolution:" << ans_resolution;
            // 需要考虑比例问题
            if (ans_resolution.width() && ans_resolution.height()) {
                QCameraViewfinderSettings the_camera_setting;
                the_camera_setting.setResolution(ans_resolution);
                this->camera->setViewfinderSettings(the_camera_setting);
            }
            this->options = options;
        }
    }
}

CameraGrabberInfo CameraGrabber::getFrame(CameraGrabberOptions &options) {
    QVideoFrame the_frame = this->grabber->getCurrentFrame();
    CameraGrabberInfo ans;

    if (!the_frame.isValid()) {
        return ans;
    }

    this->autoSetSetting(options);
    the_frame.map(QAbstractVideoBuffer::ReadOnly);
    QImage::Format image_format = QVideoFrame::imageFormatFromPixelFormat(the_frame.pixelFormat());

    ans.width = the_frame.width();
    ans.height = the_frame.height();
    if (image_format != QImage::Format_Invalid) {
        QImage frame_image(
            the_frame.bits(),
            ans.width, ans.height,
            the_frame.bytesPerLine(),
            image_format
        );
        frame_image = frame_image.convertToFormat(QImage::Format_RGB32);
        ans.bits = FFmpegUtil::copyImage(frame_image);
    }
    else {
        if (the_frame.pixelFormat() == QVideoFrame::Format_YUYV) {
            uint8_t *image_np = FFmpegUtil::imageYUYV2BGRA(the_frame.bits(), ans.width, ans.height);
            ans.bits = image_np;
        }
        else {
            QImage frame_image = QImage::fromData(the_frame.bits(), the_frame.mappedBytes());
            frame_image = frame_image.convertToFormat(QImage::Format_RGB32);
            ans.bits = FFmpegUtil::copyImage(frame_image);
        }
    }

    the_frame.unmap();

    return ans;
}
