#include "image_provider.h"
#include "image_pool.h"

ImageProvider::ImageProvider() : QQuickImageProvider(QQuickImageProvider::Image) {
}

QImage ImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    QImage *the_image = ImagePool::instance()->getImage(id.toInt());
    if (the_image) {
        return *the_image;
    }
    else {
        return QImage();
    }
}
