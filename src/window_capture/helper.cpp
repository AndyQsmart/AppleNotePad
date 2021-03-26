#include "helper.h"
#include <dwmapi.h>
#include <stdlib.h>
#include <QString>
using namespace WindowCaptureCore;

const bool EXCLUDE_MINIMIZED = true;

QString Helper::hwnd2Str(HWND hwnd) {
    size_t hwnd_value = reinterpret_cast<size_t>(hwnd);
    return QString::number(hwnd_value);
}

HWND Helper::str2Hwnd(QString s_hwnd) {
    size_t hwnd_value = s_hwnd.toULongLong();
    HWND hwnd = reinterpret_cast<HWND>(hwnd_value);
    return hwnd;
}

QString Helper::getHwndClassName(HWND hwnd) {
    wchar_t class_name_temp[256];
    class_name_temp[0] = 0;
    if (GetClassNameW(hwnd, class_name_temp, sizeof(class_name_temp) / sizeof(wchar_t))) {
        return QString::fromWCharArray(class_name_temp);
    }
    return QString("");
}

QString Helper::getHwndtWindowText(HWND hwnd) {
    wchar_t *temp;
    int len;

    len = GetWindowTextLengthW(hwnd);
    if (!len)
        return QString("");

    temp = (wchar_t *)malloc(sizeof(wchar_t) * (len+1));
    if (GetWindowTextW(hwnd, temp, len+1)) {
        QString window_text = QString::fromWCharArray(temp);
        free(temp);
        return window_text;
    }
    free(temp);
    return QString("");
}

bool Helper::checkWindowValid(HWND hwnd) {
    if (!IsWindowVisible(hwnd) || (EXCLUDE_MINIMIZED && IsIconic(hwnd))) {
        return false;
    }

    DWORD styles = (DWORD)GetWindowLongPtr(hwnd, GWL_STYLE);
    if (styles & WS_CHILD) {
        return false;
    }

    DWORD ex_styles = (DWORD)GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    if (ex_styles & WS_EX_TOOLWINDOW) {
        return false;
    }

    RECT rect;
    GetClientRect(hwnd, &rect);
    if (EXCLUDE_MINIMIZED && (rect.bottom == 0 || rect.right == 0)) {
        return false;
    }

    DWORD isCloacked;
    if (SUCCEEDED(DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &isCloacked, sizeof(isCloacked)))) {
        if (isCloacked != 0) {
            return false;
        }
    }

    return true;
}
