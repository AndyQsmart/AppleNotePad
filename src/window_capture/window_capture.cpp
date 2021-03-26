#include "window_capture.h"
#include "helper.h"
#include "src/image_util/image_pool.h"
#include "src/utils/ffmpeg_util.h"
#include <QList>
#include <QMap>
#include <QImage>
#include <QCameraInfo>
#include <QDebug>

using namespace WindowCaptureCore;

BOOL CALLBACK EnumWindowsProc(HWND hwnd,LPARAM lParam) {
    if (!Helper::checkWindowValid(hwnd)) {
        return TRUE;
    }

    VariantList *the_windows = (VariantList *)lParam;
    VariantMap the_win = VariantMap();

    the_win["hwnd"] = QVariant(Helper::hwnd2Str(hwnd));
    the_win["className"] = QVariant(Helper::getHwndClassName(hwnd));
    the_win["windowText"] = QVariant(Helper::getHwndtWindowText(hwnd));
    the_windows->push_back(QVariant(the_win));

    return TRUE;
}

QVariant WindowCapture::getWindowList() const {
    VariantList the_windows = VariantList();
    EnumWindows(EnumWindowsProc, (LPARAM)&the_windows);
    return QVariant(the_windows);
}

QVariant WindowCapture::getDesktopWindow() const {
    HWND hwnd = GetDesktopWindow();
    VariantMap ans;
    ans["hwnd"] = Helper::hwnd2Str(hwnd);

    return QVariant(ans);
}

QVariant WindowCapture::getCameraList() const {
    QList<QCameraInfo> cameras = QCameraInfo::availableCameras();
    int length = cameras.length();
    VariantList ans;
    for (int i = 0; i < length; i++) {
        QCameraInfo *the_camera = &(cameras[i]);
        VariantMap item;
        item["deviceName"] = the_camera->deviceName();
        item["description"] = the_camera->description();
        ans.push_back(QVariant(item));
    }
    return QVariant(ans);
}

CaptureWindowResult WindowCapture::CaptureWindw(HWND hwnd, CaptureWindowOptions options) {
//    qDebug() << "enter capture window";
    // 获取窗口位置信息
    RECT rect;
    GetClientRect(hwnd, &rect);
    int width = rect.right-rect.left;
    int height = rect.bottom-rect.top;
//    qDebug() << "get client rect";

    // 通过内存DC复制客户区到DDB位图
    HDC wnd_hdc = GetDC(hwnd);
    HDC mem_hdc = CreateCompatibleDC(wnd_hdc);
    HBITMAP h_bmp = CreateCompatibleBitmap(wnd_hdc, width, height);
    SelectObject(mem_hdc, h_bmp);
//    qDebug() << "select object dc";

    // 读取显示缓冲区内存数据
    // CAPTUREBLT = 1073741824
    // CAPTUREBLT = 0x40000000
    BitBlt(mem_hdc, 0, 0, width, height, wnd_hdc, 0, 0, SRCCOPY);
//    qDebug() << "bitblt";

    if (options.enable_cursor) {
        if (options.force_cursor || hwnd == GetForegroundWindow()) {
            CURSORINFO cursor_info;
            cursor_info.cbSize = sizeof(CURSORINFO);
            GetCursorInfo(&cursor_info);
            if (cursor_info.flags & CURSOR_SHOWING) {
                ICONINFO icon_info;
                GetIconInfo(cursor_info.hCursor, &icon_info);
                POINT point_in_w;
                point_in_w.x = cursor_info.ptScreenPos.x;
                point_in_w.y = cursor_info.ptScreenPos.y;
                ScreenToClient(hwnd, &point_in_w);
                int x_in_w = point_in_w.x-icon_info.xHotspot;
                int y_in_w = point_in_w.y-icon_info.yHotspot;
                BITMAP cursor_bmp;
                GetObject(icon_info.hbmColor, sizeof(BITMAP), &cursor_bmp); // 返回PyBITMAP类型 可以获得光标尺寸，注意，这里最好放入黑白位图来获取，放入彩色位图可能导致单色光标报错
                DrawIconEx(mem_hdc, x_in_w, y_in_w, cursor_info.hCursor, cursor_bmp.bmWidth, cursor_bmp.bmHeight, 0, NULL, DI_NORMAL);
           }
       }
    }

    // 获取位图信息
    BITMAP bmp;
    GetObject(h_bmp, sizeof(BITMAP), &bmp);
    int image_width = bmp.bmWidth;
    int image_height = bmp.bmHeight;
    int image_channels = bmp.bmBitsPixel == 1 ? 1 : bmp.bmBitsPixel/8;
    int bit_size = image_width*image_height*image_channels;
//    uint8_t* bmp_bits = new uint8_t[bit_size];
    uint8_t* bmp_bits = FFmpegUtil::avMalloc(bit_size);
    GetBitmapBits(h_bmp, bit_size, bmp_bits);

    DeleteDC(wnd_hdc);
    DeleteDC(mem_hdc);
    ReleaseDC(hwnd, wnd_hdc);
    DeleteObject(h_bmp);
//    qDebug() << "delete object";

    CaptureWindowResult ans;
    ans.bits = bmp_bits;
    ans.width = image_width;
    ans.height = image_height;
    ans.channels = image_channels;

    return ans;
}

CaptureWindowOptions DEFAULT_CAPTURE_WINDOW_OPTIONS;

CaptureWindowResult WindowCapture::CaptureWindw(HWND hwnd) {
    return WindowCapture::CaptureWindw(hwnd, DEFAULT_CAPTURE_WINDOW_OPTIONS);
}

QVariant WindowCapture::getWindowImage(QVariant q_hwnd) const {
    HWND hwnd = Helper::str2Hwnd(q_hwnd.toString());
    CaptureWindowResult image_data = WindowCapture::CaptureWindw(hwnd);
    QImage *image = new QImage(image_data.bits, image_data.width, image_data.height, QImage::Format_RGB32);
    int image_id = ImagePool::instance()->addImage(image, image_data.bits);
    return QVariant(image_id);
}
