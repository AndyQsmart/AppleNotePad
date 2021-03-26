#include "image_pool.h"
#include "src/utils/ffmpeg_util.h"

ImagePool *ImagePool::_instance = nullptr;

ImagePool::ImagePool() {
    this->_current_id = 0;
}

QImage *ImagePool::getImage(int image_id) {
     return this->_image_map[image_id];
}

int ImagePool::addImage(QImage *q_image) {
    int the_id = this->_current_id;
    this->_image_map[the_id] = q_image;
    this->_current_id += 1;
    return the_id;
}

int ImagePool::addImage(QImage *q_image, uint8_t *buffer) {
    int the_id = ImagePool::addImage(q_image);
    this->_image_buffer_map[the_id] = buffer;
    return the_id;
}

void ImagePool::releaseImage(int image_id) {
    QImage *the_image = this->_image_map[image_id];
    if (the_image) {
        this->_image_map.remove(image_id);
        delete the_image;
    }
    uint8_t *buffer = this->_image_buffer_map[image_id];
    if (buffer) {
        this->_image_buffer_map.remove(image_id);
//        delete buffer;
        FFmpegUtil::avFree(buffer);
    }
}
