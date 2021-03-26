#ifndef QMLSIGNAL_H
#define QMLSIGNAL_H

#include <QObject>
#include <QVariant>

enum QMLSignalCMD {
    REFRESH_MEDIA_STREAM_INFO = 1,
    AUDIO_AVG_DATA = 2,
};

class QMLSignal : public QObject {
    Q_OBJECT

private:
    static QMLSignal *_instance;

public:
    static QMLSignal *instance();
    void emitSignal(QMLSignalCMD cmd, QVariant data);

signals:
    void qmlSignal(int cmd, QVariant data);
};

#endif // QMLSIGNAL_H
