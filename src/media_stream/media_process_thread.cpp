#include "media_process_thread.h"
#include "media_frame_provider.h"
#include "src/media_stream/media_graber/window_grabber.h"
#include "src/media_stream/media_graber/camera_grabber.h"
#include "src/window_capture/window_capture.h"
#include "src/window_capture/helper.h"
#include "src/utils/ffmpeg_util.h"
#include "src/utils/qml_signal.h"
#include <windows.h>
#include <QTime>
#include <QMutex>
#include <QVariant>
#include <QString>
#include <QMap>
#include <QList>
#include <QMutexLocker>
#include <QVideoFrame>
#include <QJSValue>
#include <QImage>
#include <QtDebug>


MediaProcessThread::MediaProcessThread() {
    this->run_mutex = new QMutex();
    this->record_mutex = new QMutex();
}

MediaProcessThread::~MediaProcessThread() {
    delete this->run_mutex;
    delete this->record_mutex;
}

void MediaProcessThread::setFrameData(QVariant frame_data) {
    // 需要加锁
    VariantList variant_list =  frame_data.value<QJSValue>().toVariant().toList();
    int length = variant_list.length();
    FrameData ans_frame_data;
    for (int i = 0; i < length; i++) {
        QVariant the_frame_data_variant = variant_list[i];
        if (the_frame_data_variant.isNull()) {
            ans_frame_data.push_back(FrameDataItem());
        }
        else {
            VariantMap the_data_variant_map = the_frame_data_variant.toMap();
            FrameDataItem frame_data_item;
            frame_data_item.type = the_data_variant_map["type"].toInt();
            QMap<QString, QString> data_data;
            VariantMap data_data_variant = the_data_variant_map["data"].toMap();
            VariantMap::iterator it = data_data_variant.begin();
            while (it != data_data_variant.end()) {
                data_data[it.key()] = it.value().toString();
                it++;
            }
            frame_data_item.data = data_data;
            ans_frame_data.push_back(frame_data_item);
        }
    }
    // 先初始化所需的捕捉器
    this->initMediaGrabber(ans_frame_data);
    FrameData old_frame_data = this->_frame_data;
    this->_frame_data = ans_frame_data;
    // 释放老的捕捉器
    this->releaseMediaGrabber(old_frame_data, ans_frame_data);
}

void MediaProcessThread::initMediaGrabber(FrameData &frame_data) {
//    qDebug() << "initMediaGrabber";
    double frame_rate = this->_config_data.frame_rate;
    int frame_data_length = frame_data.length();
    for (int i = 0; i < frame_data_length; i++) {
        FrameDataItem *the_frame_data = &(frame_data[i]);
        int frame_type = the_frame_data->type;
        if (frame_type == FrameType::NONE) {
            continue;
        }
        QMap<QString, QString> *the_data = &(the_frame_data->data);
        switch (frame_type) {
            case FrameType::CAMERA: {
                QString deviceName_str = (*the_data)["deviceName"];
                CameraGrabber *the_grabber = this->camera_grabber_map[deviceName_str];
                if (the_grabber) {
                    if (the_grabber->isStoped()) {
                        the_grabber->start();
                    }
                }
                else {
                    CameraGrabberOptions options;
                    options.device_name = deviceName_str.toUtf8();
//                    options.width =
                    the_grabber = new CameraGrabber(options);
                    this->camera_grabber_map[deviceName_str] = the_grabber;
                    the_grabber->start();
                }
                break;
            }
            case FrameType::WINDOW:
            case FrameType::DESKTOP: {
                QString hwnd_str = (*the_data)["hwnd"];
                HWND hwnd = WindowCaptureCore::Helper::str2Hwnd(hwnd_str);
                WindowGrabber *the_grabber = this->window_grabber_map[hwnd_str];
                if (the_grabber) {
                    if (the_grabber->isStoped()) {
                        the_grabber->start();
                    }
                }
                else {
                    WindowGrabberOptions options;
                    options.frame_rate = frame_rate;
                    options.frame_type = frame_type;
                    options.hwnd = hwnd;
                    the_grabber = new WindowGrabber(options);
                    // 需要加锁
                    this->window_grabber_map[hwnd_str] = the_grabber;
                    the_grabber->start();
                }
                break;
            }
        }
    }
//    qDebug() << "end initMediaGrabber";
}

void MediaProcessThread::releaseMediaGrabber(FrameData &old_frame_data, FrameData &new_frame_data) {
    QMap<QString, bool> stay_window_map;
    QMap<QString, bool> stay_camera_map;
    int new_frame_data_length = new_frame_data.length();
    for (int i = 0; i < new_frame_data_length; i++) {
        FrameDataItem *the_frame_data = &(new_frame_data[i]);
        int frame_type = the_frame_data->type;
        if (frame_type == FrameType::NONE) {
            continue;
        }
        QMap<QString, QString> *the_data = &(the_frame_data->data);
        switch (frame_type) {
            case FrameType::CAMERA: {
                QString deviceName_str = (*the_data)["deviceName"];
                stay_camera_map[deviceName_str] = true;
                break;
            }
            case FrameType::WINDOW:
            case FrameType::DESKTOP: {
                QString hwnd_str = (*the_data)["hwnd"];
                stay_window_map[hwnd_str] = true;
                break;
            }
        }
    }

    int old_frame_data_length = old_frame_data.length();
    for (int i = 0; i < old_frame_data_length; i++) {
        FrameDataItem *the_frame_data = &(old_frame_data[i]);
        int frame_type = the_frame_data->type;
        if (frame_type == FrameType::NONE) {
            continue;
        }
        QMap<QString, QString> *the_data = &(the_frame_data->data);
        switch (frame_type) {
            case FrameType::CAMERA: {
                QString deviceName_str = (*the_data)["deviceName"];
                if (!stay_camera_map[deviceName_str]) {
                    CameraGrabber *the_grabber = this->camera_grabber_map[deviceName_str];
                    if (the_grabber) {
                        the_grabber->stop();
                    }
                }
                break;
            }
            case FrameType::WINDOW:
            case FrameType::DESKTOP: {
                QString hwnd_str = (*the_data)["hwnd"];
                if (!stay_window_map[hwnd_str]) {
                    WindowGrabber *the_grabber = this->window_grabber_map[hwnd_str];
                    if (the_grabber) {
                        the_grabber->stop();
                    }
                }
                break;
            }
        }
    }
}

void MediaProcessThread::setLayoutData(QVariant layout_data) {
    VariantList variant_list =  layout_data.value<QJSValue>().toVariant().toList();
    int length = variant_list.length();
    this->_layout_data.clear();
    for (int i = 0; i < length; i++) {
        VariantMap the_data_variant_map = variant_list[i].toMap();
        LayoutDataItem layout_data_item;
        layout_data_item.width = the_data_variant_map["width"].toDouble();
        layout_data_item.height = the_data_variant_map["height"].toDouble();
        layout_data_item.top = the_data_variant_map["top"].toDouble();
        layout_data_item.left = the_data_variant_map["left"].toDouble();
        VariantList align_list_variant = the_data_variant_map["align"].toList();
        int the_length = align_list_variant.length();
        for (int j = 0; j < the_length; j++) {
            layout_data_item.align.push_back(align_list_variant[j].toString());
        }
        this->_layout_data.push_back(layout_data_item);
    }
}

void MediaProcessThread::setConfigData(QVariant config_data) {
    VariantMap variant_map =  config_data.value<QJSValue>().toVariant().toMap();
    this->_config_data.width = variant_map["width"].toInt();
    this->_config_data.height = variant_map["height"].toInt();
    this->_config_data.frame_rate = variant_map["frame_rate"].toDouble();
}

ImagePosStruct MediaProcessThread::calImagePos(int image_width, int image_height, int canvas_width, int canvas_height, LayoutDataItem &the_layout) {
    double to_width = the_layout.width*canvas_width;
    double to_height = the_layout.height*canvas_height;
    double to_left = the_layout.left*canvas_width;
    double to_top = the_layout.top*canvas_height;
    QList<QString> *align = &(the_layout.align);

    // 尺寸比例相同
    // if to_height/to_width == real_height/real_width:
    if (to_height*image_width == image_height*to_width) {
        ImagePosStruct ans;
        ans.width = to_width; ans.height = to_height;
        ans.left = to_left; ans.top = to_top;
        return ans;
    }

    // 特殊布局
    QMap<QString, bool> align_map;
    int align_length = align->length();
    for (int i = 0; i < align_length; i++) {
        align_map[(*align)[i]] = true;
    }

    double ans_width = to_width;
    double ans_height = to_height;
    double ans_left = to_left;
    double ans_top = to_top;
    if ((double)to_height/to_width > (double)image_height/image_width) {
        ans_width = to_width;
        ans_height = ans_width * image_height/image_width;
        ans_left = to_left;
        if (align_map["top"]) {
            ans_top = to_top;
        }
        else if (align_map["bottom"]) {
            ans_top = to_top + (to_height-ans_height);
        }
        else {
            ans_top = to_top + int((to_height-ans_height)/2);
        }
    }
    else {
        ans_height = to_height;
        ans_width = ans_height * image_width/image_height;
        ans_top = to_top;
        if (align_map["left"]) {
            ans_left = to_left;
        }
        else if (align_map["right"]) {
            ans_left = to_left + (to_width-ans_width);
        }
        else {
            ans_left = to_left + (to_width-ans_width)/2;
        }
    }
    ImagePosStruct ans;
    ans.width = (int)ans_width; ans.height = (int)ans_height;
    ans.left = (int)ans_left; ans.top = (int)ans_top;
    return ans;
}

void MediaProcessThread::run() {
    this->run_mutex->lock();
    this->stoped = false;
    this->run_mutex->unlock();

    int ans_width = this->_config_data.width;
    int ans_height = this->_config_data.height;
    double frame_rate = this->_config_data.frame_rate;
    MediaFrameProvider::instance()->setFormat(ans_width, ans_height, QVideoFrame::Format_YUV420P);

    while (true) {
        this->run_mutex->lock();
        if (this->stoped) {
            this->run_mutex->unlock();
            break;
        }
        this->run_mutex->unlock();

        QTime frame_start_time = QTime::currentTime();

//        qDebug() << "run";
        int ans_image_size = FFmpegUtil::getFormatSize(AV_PIX_FMT_BGRA, ans_width, ans_height);
        uint8_t *image_np = FFmpegUtil::avMalloc(ans_image_size);
        if (this->_frame_data.length()) {
            int frame_data_length = this->_frame_data.length();
            int layout_data_length = this->_layout_data.length();
            for (int i = 0; i < frame_data_length; i++) {
                FrameDataItem *the_frame_data = &(this->_frame_data[i]);
                int frame_type = the_frame_data->type;
                if (frame_type == FrameType::NONE) {
                    continue;
                }
                if (i >= layout_data_length) {
                    continue;
                }
                QMap<QString, QString> *the_data = &(the_frame_data->data);
                LayoutDataItem *the_layout = &(this->_layout_data[i]);
//                int layout_width = the_layout->width;
//                int layout_height = the_layout->height;
//                double layout_top = the_layout->top;
//                double layout_left = the_layout->left;
//                QList<QString> *layout_align = &(the_layout->align);

                uint8_t *the_np = nullptr;
                int the_width = 0;
                int the_height = 0;
                switch (frame_type) {
                    case FrameType::CAMERA: {
                        QString deviceName_str = (*the_data)["deviceName"];
                        CameraGrabberOptions options;
                        options.width = the_layout->width*ans_width;
                        options.height = the_layout->height*ans_height;
                        CameraGrabberInfo result = this->camera_grabber_map[deviceName_str]->getFrame(options);
                        the_np = result.bits;
                        the_width = result.width;
                        the_height = result.height;
                        break;
                    }
                    case FrameType::WINDOW:
                    case FrameType::DESKTOP: {
                        QString hwnd_str = (*the_data)["hwnd"];
                        WindowGrabberInfo result = this->window_grabber_map[hwnd_str]->getFrame();
                        the_np = result.bits;
                        the_width = result.width;
                        the_height = result.height;
                        break;
                    }
                }
                if (the_np && the_width && the_height) {
//                    qDebug() << "the_np is ok";
                    ImagePosStruct pos = this->calImagePos(the_width, the_height, ans_width, ans_height, *the_layout);
//                    qDebug() << "cal pos";
                    uint8_t *resize_np = the_np;
                    if (the_width != pos.width || the_height != pos.height) {
//                        qDebug() << the_width;
//                        qDebug() << pos.width;
                        resize_np = FFmpegUtil::resizeBGRAImage(the_np, the_width, the_height, pos.width, pos.height);
                        FFmpegUtil::avFree(the_np);
                    }
//                    qDebug() << "before combine";
                    FFmpegUtil::combineBGRAImage(
                        image_np, ans_width,
                        pos.left, pos.top,
                        resize_np, pos.width,
                        0, 0, pos.width, pos.height
                    );
//                    qDebug() << "after combine";
                    FFmpegUtil::avFree(resize_np);
//                    image_np = resize_np;
                }
            }
        }
//        qDebug() << "before emit";
        if (image_np) {
            QImage *image = new QImage(image_np, ans_width, ans_height, QImage::Format_RGB32);
            emit this->newFrameData(image->copy());
//            delete image_np;
            FFmpegUtil::avFree(image_np);
//            FFmpegUtil::avFree(image_np);
        }
//        qDebug() << "after emit";

//        QMap<QString, QVariant> the_info;
//        QTime now_time = QTime::currentTime();
//        int t_ms_diff = frame_start_time.msecsTo(now_time);
//        the_info["duration"] = QVariant(t_ms_diff);
//        the_info["fps"] = QVariant("60");
//        the_info["speed"] = QVariant("1");
//        QMLSignal::instance()->emitSignal(QMLSignalCMD::REFRESH_MEDIA_STREAM_INFO, QVariant(the_info));

        QTime frame_end_time = QTime::currentTime();
        int ms_diff = frame_start_time.msecsTo(frame_end_time);
//        qDebug() << ms_diff;
        int next_frame_time = int(1000.0/frame_rate-ms_diff);
        if (next_frame_time > 0) {
            this->msleep(next_frame_time);
        }
    }
    // 结束后释放捕捉器
    QMap<QString, WindowGrabber *>::iterator ita = this->window_grabber_map.begin();
    while (ita != this->window_grabber_map.end()) {
        ita.key();
        ita.value();
        ita++;
    }
    this->window_grabber_map;
    this->camera_grabber_map;
}

void MediaProcessThread::stop() {
    QMutexLocker locker(this->run_mutex);
    this->stoped = true;
}

bool MediaProcessThread::isStoped() {
    QMutexLocker locker(this->run_mutex);
    return this->stoped;
}
