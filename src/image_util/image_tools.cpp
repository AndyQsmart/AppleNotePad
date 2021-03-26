#include "image_tools.h"
#include "image_pool.h"

void ImageTools::releaseImage(QVariant q_image_id) const {
    int image_id = q_image_id.toString().toInt();
    ImagePool::instance()->releaseImage(image_id);
}
