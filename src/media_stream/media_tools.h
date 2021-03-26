#ifndef MEDIATOOLS_H
#define MEDIATOOLS_H

#include <QObject>
#include <QVariant>

class MediaProcessThread;

class MediaTools : public QObject {
    Q_OBJECT

private:
    MediaProcessThread *_media_process_thread;

public:
    MediaTools(QObject *parent=nullptr);
    ~MediaTools();
    Q_INVOKABLE void startMediaProcess(QVariant frame_data, QVariant layout_data, QVariant config_data) const;
    Q_INVOKABLE void setMediaData(QVariant frame_data, QVariant layout_data) const;
    Q_INVOKABLE void stopMediaProcess() const;
};

#endif // MEDIATOOLS_H
