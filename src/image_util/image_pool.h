#ifndef IMAGEPOOL_H
#define IMAGEPOOL_H

#include <QMap>
#include <QImage>

using ImageMap = QMap<int, QImage *>;
using ImageBufferMap = QMap<int, uint8_t*>;

class ImagePool {
private:
    static ImagePool *_instance;
    int _current_id = 0;
    ImageMap _image_map;
    ImageBufferMap _image_buffer_map;

public:
    ImagePool();

    static ImagePool * instance() {
        if (ImagePool::_instance == nullptr) {
            ImagePool::_instance = new ImagePool();
        }
        return ImagePool::_instance;
    }

    QImage *getImage(int image_id);
    int addImage(QImage *q_image);
    int addImage(QImage *q_image, uint8_t *buffer);
    void releaseImage(int image_id);
};

#endif // IMAGEPOOL_H
