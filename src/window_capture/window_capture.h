#ifndef WINDOWCAPTURE_H
#define WINDOWCAPTURE_H

#include <windows.h>
#include <QObject>
#include <QVariant>
#include <QList>
#include <QMap>
#include <QString>

enum FrameType {
    NONE = 0,
    WINDOW = 1,
    DESKTOP = 2,
    CAMERA = 3,
};


using MapList = QList<QMap<QString, QString> >;
using VariantList = QList<QVariant>;
using StringMap = QMap<QString, QString>;
using VariantMap = QMap<QString, QVariant>;

struct CaptureWindowOptions {
    bool enable_cursor = false;
    bool force_cursor = false;
};

struct CaptureWindowResult {
    uint8_t *bits = nullptr;
    int width = 0;
    int height = 0;
    int channels = 0;
};

class WindowCapture : public QObject {
    Q_OBJECT

public:
    Q_INVOKABLE QVariant getCameraList() const;
    Q_INVOKABLE QVariant getWindowList() const;
    Q_INVOKABLE QVariant getDesktopWindow() const;
    Q_INVOKABLE QVariant getWindowImage(QVariant q_hwnd) const;
    static CaptureWindowResult CaptureWindw(HWND hwnd, CaptureWindowOptions options);
    static CaptureWindowResult CaptureWindw(HWND hwnd);
};

#endif // WINDOWCAPTURE_H
