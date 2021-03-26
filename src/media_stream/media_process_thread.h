#ifndef MEDIAPROCESSTHREAD_H
#define MEDIAPROCESSTHREAD_H

#include <QThread>
#include <QVariant>
#include <QMap>
#include <QList>
#include <QString>
#include <QImage>

struct FrameDataItem {
    int type = 0;
    QMap<QString, QString> data;
};

struct LayoutDataItem {
    double width = 0;
    double height = 0;
    double top = 0;
    double left = 0;
    QList<QString> align;
};

struct ConfigData {
    int width = 0;
    int height = 0;
    double frame_rate = 0;
};

struct ImagePosStruct {
    int width = 0;
    int height = 0;
    int left = 0;
    int top = 0;
};

using FrameData = QList<FrameDataItem>;
using LayoutData = QList<LayoutDataItem>;
using VariantList = QList<QVariant>;
using VariantMap = QMap<QString, QVariant>;

class QMutex;
class WindowGrabber;
class CameraGrabber;

class MediaProcessThread : public QThread {
    Q_OBJECT

private:
    // 状态数据
    bool stoped = false;
    bool is_recording = false;
    int record_start_time_stamp = 0;
    // 线程锁
    QMutex *run_mutex;
    QMutex *record_mutex;
    // 画面、布局、配置等相关数据
    FrameData _frame_data;
    LayoutData _layout_data;
    ConfigData _config_data;
    // 画面捕捉相关
    QMap<QString, WindowGrabber *> window_grabber_map;
    QMap<QString, CameraGrabber *> camera_grabber_map;

public:
    MediaProcessThread();
    ~MediaProcessThread();
    ImagePosStruct calImagePos(int image_width, int image_height, int canvas_width, int canvas_height, LayoutDataItem &the_layout);
    void setFrameData(QVariant frame_data);
    void setLayoutData(QVariant layout_data);
    void setConfigData(QVariant config_data);
    void initMediaGrabber(FrameData &frame_data);
    void releaseMediaGrabber(FrameData &old_frame_data, FrameData &new_frame_data);
    void run();
    void stop();
    bool isStoped();

signals:
    void newFrameData(QImage frame);
};

#endif // MEDIAPROCESSTHREAD_H
