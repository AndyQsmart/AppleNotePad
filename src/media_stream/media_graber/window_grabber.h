#ifndef WINDOWGRABBER_H
#define WINDOWGRABBER_H

#include <QThread>
#include <windows.h>

class QMutex;

struct WindowGrabberOptions {
    HWND hwnd;
    int frame_type = 0;
    double frame_rate = 0;
};

struct WindowGrabberInfo {
    uint8_t *bits = nullptr;
    int width = 0;
    int height = 0;
    int channels = 0;
};

class WindowGrabber : public QThread {
    Q_OBJECT

private:
    // 状态数据
    bool stoped = false;
    WindowGrabberOptions options;
    WindowGrabberInfo current_np;
    // 线程锁
    QMutex *run_mutex;
    QMutex *frame_mutex;

public:
    WindowGrabber(WindowGrabberOptions options);
    ~WindowGrabber();
    WindowGrabberInfo getFrame();
    void run();
    void stop();
    bool isStoped();
};

#endif // WINDOWGRABBER_H
