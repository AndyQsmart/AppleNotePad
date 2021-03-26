#ifndef MEDIAFRAMEPROVIDER_H
#define MEDIAFRAMEPROVIDER_H

#include <QObject>
#include <QVideoSurfaceFormat>
#include <QVideoFrame>
#include <QImage>

class QAbstractVideoSurface;

class MediaFrameProvider : public QObject {
    Q_OBJECT
    Q_PROPERTY(QAbstractVideoSurface *videoSurface READ getVideoSurface WRITE setVideoSurface)

private:
    static MediaFrameProvider *_instance;
    QAbstractVideoSurface *m_surface = nullptr;
    QVideoSurfaceFormat m_format;

public:
    MediaFrameProvider(QObject *parent=nullptr);
    static MediaFrameProvider *instance();
    QAbstractVideoSurface *getVideoSurface();
    void setVideoSurface(QAbstractVideoSurface *surface);
    void setFormat(int width, int heigth, QVideoFrame::PixelFormat the_format);

public slots:
    void onNewVideoContentReceived(const QImage &frame);
};

#endif // MEDIAFRAMEPROVIDER_H
