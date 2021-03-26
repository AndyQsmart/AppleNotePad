pragma Singleton

import QtQuick 2.0
import "../../../common_js/Tools.js" as Tools

Item {
    readonly property var frameType: ({
        WINDOW: 1,
        DESKTOP: 2,
        CAMERA: 3,
    })

    function getWindowList() {
        let window_list = WindowCapture.getWindowList()
        console.log("(FrameUtil.qml)getWindowList", JSON.stringify(window_list))
        return window_list
    }

    function getDesktopList() {
        let desktop_list = [WindowCapture.getDesktopWindow()]
        console.log("(FrameUtil.qml)getDesktopList", JSON.stringify(desktop_list))
        return desktop_list
    }

    function getCameraList() {
        let camera_list = WindowCapture.getCameraList()
        console.log("(FrameUtil.qml)getCameraList", JSON.stringify(camera_list))
        return camera_list
    }

    function getFrameName(type, data) {
        switch (type) {
            case frameType.WINDOW:
                return data.windowText
            case frameType.DESKTOP:
                return '桌面'
            case frameType.CAMERA:
                return data.description
        }
    }

    function getFrameImage(type, data) {
        switch (type) {
            case frameType.WINDOW:
                return WindowCapture.getWindowImage(data.hwnd)
            case frameType.DESKTOP:
                return WindowCapture.getWindowImage(data.hwnd)
        }
    }

    function compareFrameData(type, data1, data2) {
        switch (type) {
            case frameType.WINDOW:
                return data1.hwnd === data2.hwnd
            case frameType.DESKTOP:
                return data1.hwnd === data2.hwnd
            case frameType.CAMERA:
                return data1.deviceName === data2.deviceName
        }
    }
}
