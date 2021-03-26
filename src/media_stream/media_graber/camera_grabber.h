#ifndef CAMERAGRABBER_H
#define CAMERAGRABBER_H

#include <QObject>
#include <QAbstractVideoSurface>
#include <QAbstractVideoBuffer>
#include <QVideoFrame>
#include <QList>
#include <QByteArray>

class QCamera;

class CameraFrameGrabberSurface : public QAbstractVideoSurface {
private:
    QVideoFrame current_frame;

public:
    CameraFrameGrabberSurface(QObject *parent = nullptr);
    QList<QVideoFrame::PixelFormat> supportedPixelFormats(QAbstractVideoBuffer::HandleType type = QAbstractVideoBuffer::NoHandle) const;
    bool present(const QVideoFrame &frame);
    QVideoFrame getCurrentFrame();
};

struct CameraGrabberOptions {
    QByteArray device_name;
    int width = 0;
    int height = 0;
};

struct CameraGrabberInfo {
    uint8_t *bits = nullptr;
    int width = 0;
    int height = 0;
    int channels = 0;
};

class CameraGrabber {
private:
    bool stoped = true;
    CameraGrabberOptions options;
    QCamera *camera;
    CameraFrameGrabberSurface *grabber;

public:
    CameraGrabber(CameraGrabberOptions options);
    ~CameraGrabber();
    void start();
    void stop();
    bool isStoped();
    void autoSetSetting(CameraGrabberOptions &options, bool force_set = false);
    CameraGrabberInfo getFrame(CameraGrabberOptions &options);
};

#endif // CAMERAGRABBER_H
