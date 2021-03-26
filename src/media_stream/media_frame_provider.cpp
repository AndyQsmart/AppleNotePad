#include "media_frame_provider.h"
#include <QAbstractVideoSurface>
#include <QSize>
#include <QtDebug>

MediaFrameProvider *MediaFrameProvider::_instance = nullptr;

MediaFrameProvider::MediaFrameProvider(QObject *parent) : QObject(parent) {

}

MediaFrameProvider *MediaFrameProvider::instance() {
    if (MediaFrameProvider::_instance == nullptr) {
        MediaFrameProvider::_instance = new MediaFrameProvider();
    }
    return MediaFrameProvider::_instance;
}

QAbstractVideoSurface *MediaFrameProvider::getVideoSurface() {
    return this->m_surface;
}

void MediaFrameProvider::setVideoSurface(QAbstractVideoSurface *surface) {
    if (this->m_surface && this->m_surface != surface && this->m_surface->isActive()) {
        this->m_surface->stop();
    }
    this->m_surface = surface;

    if (this->m_surface && this->m_format.isValid()) {
        this->m_format = this->m_surface->nearestFormat(this->m_format);
        this->m_surface->start(this->m_format);
    }
}

void MediaFrameProvider::setFormat(int width, int height, QVideoFrame::PixelFormat the_format) {
    this->m_format = QVideoSurfaceFormat(QSize(width, height), the_format);

    if (this->m_surface) {
        if (this->m_surface->isActive()) {
            this->m_surface->stop();
        }
        this->m_format = this->m_surface->nearestFormat(this->m_format);
        this->m_surface->start(this->m_format);
    }
}

void MediaFrameProvider::onNewVideoContentReceived(const QImage &frame) {
    if (this->m_surface) {
        this->m_surface->present(QVideoFrame(frame));
    }
}
