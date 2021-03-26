#ifndef HELPER_H
#define HELPER_H

#include "windows.h"

class QString;

namespace WindowCaptureCore {
    class Helper {
    public:
        static bool checkWindowValid(HWND hwnd);
        static QString hwnd2Str(HWND hwnd);
        static HWND str2Hwnd(QString s_hwnd);
        static QString getHwndClassName(HWND hwnd);
        static QString getHwndtWindowText(HWND hwnd);
    };
}

#endif // HELPER_H
