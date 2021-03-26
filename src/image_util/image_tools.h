#ifndef IMAGETOOLS_H
#define IMAGETOOLS_H

#include <QObject>
#include <QVariant>

class ImageTools : public QObject {
    Q_OBJECT

public:
    Q_INVOKABLE void releaseImage(QVariant q_image_id) const;
};

#endif // IMAGETOOLS_H
