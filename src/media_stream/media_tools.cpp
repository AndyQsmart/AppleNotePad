#include "media_tools.h"
#include "media_process_thread.h"
#include "media_frame_provider.h"
#include <QImage>
#include <QDebug>

MediaTools::MediaTools(QObject *parent) : QObject(parent) {
    this->_media_process_thread = new MediaProcessThread();
}

MediaTools::~MediaTools() {
    delete this->_media_process_thread;
}

void MediaTools::startMediaProcess(QVariant frame_data, QVariant layout_data, QVariant config_data) const {
    if (!config_data.isNull()) {
        this->_media_process_thread->setConfigData(config_data);
    }
    if (!frame_data.isNull()) {
        this->_media_process_thread->setFrameData(frame_data);
    }
    if (!layout_data.isNull()) {
        this->_media_process_thread->setLayoutData(layout_data);
    }
    connect(this->_media_process_thread, SIGNAL(newFrameData(QImage)), MediaFrameProvider::instance(), SLOT(onNewVideoContentReceived(QImage)));
    this->_media_process_thread->start();
}

void MediaTools::setMediaData(QVariant frame_data, QVariant layout_data) const {
    if (!frame_data.isNull()) {
        this->_media_process_thread->setFrameData(frame_data);
    }
    if (!layout_data.isNull()) {
        this->_media_process_thread->setLayoutData(layout_data);
    }
}

void MediaTools::stopMediaProcess() const {
    this->_media_process_thread->stop();
}
