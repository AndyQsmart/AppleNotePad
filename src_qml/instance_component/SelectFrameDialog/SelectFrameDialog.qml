import QtQuick 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import "../../common_component/Text/Typography"
import "../../common_component/Button/QButton"
import "../../common_component/Divider"
import "../../common_component/Icon"
import "../../common_component/Live/FrameUtil"
import "../../common_js/Color.js" as Color
import "../../common_js/Tools.js" as Tools
import "../../common_js/DefaultLayout.js" as DefaultLayout
import "../LayoutThumbnail"

Popup {
    id: selectPopup
    property var win_sources: []
    property var win_sources_capture: ({})
    property var desktop_sources: []
    property var desktop_sources_capture: ({})
    property var camera_sources: []
    property var camera_sources_capture: ({})
    property var current_select_index: -1
    signal finish(var data)

    visible: false
    padding: 0

    function releaseCapture() {
        let i = 0
        for (i = 0; i < win_sources.length; i++) {
            ImageTools.releaseImage(win_sources_capture[i])
        }
        win_sources = []
        win_sources_capture = []
        for (i = 0; i < desktop_sources.length; i++) {
            ImageTools.releaseImage(desktop_sources_capture[i])
        }
        desktop_sources = []
        desktop_sources_capture = []
    }

    function show(frame_data) {
        let i = 0
        current_select_index = -1

        // 获取摄像头相关数据
        let camera_list = FrameUtil.getCameraList()
        camera_sources = camera_list
        if (frame_data && frame_data.type === FrameUtil.frameType.CAMERA) {
            for (i = 0; i < camera_list.length; i++) {
                if (FrameUtil.compareFrameData(frame_data.type, frame_data.data, camera_list[i])) {
                    current_select_index = i
                }
            }
        }

        // 获取桌面相关句柄
        let desktop_list = FrameUtil.getDesktopList()
        desktop_sources = desktop_list
        if (frame_data && frame_data.type === FrameUtil.frameType.DESKTOP) {
            for (i = 0; i < desktop_list.length; i++) {
                if (FrameUtil.compareFrameData(frame_data.type, frame_data.data, desktop_list[i])) {
                    current_select_index = i+camera_list.length
                }
            }
        }

        // 获取窗口相关句柄
        let window_list = FrameUtil.getWindowList()
        win_sources = window_list
        if (frame_data && frame_data.type === FrameUtil.frameType.WINDOW) {
            for (i = 0; i < window_list.length; i++) {
                if (FrameUtil.compareFrameData(frame_data.type, frame_data.data, window_list[i])) {
                    current_select_index = i+camera_list.length+desktop_list.length
                }
            }
        }

        selectPopup.open()

        // 获取窗口截图
        let new_win_sources_capture = win_sources_capture
        for (i = 0; i < window_list.length; i++) {
            let image_id = FrameUtil.getFrameImage(FrameUtil.frameType.WINDOW, window_list[i])
            new_win_sources_capture[i] = image_id
        }
        win_sources_capture = new_win_sources_capture

        // 获取桌面截图
        let new_desktop_sources_capture = desktop_sources_capture
        for (i = 0; i < desktop_list.length; i++) {
            let image_id = FrameUtil.getFrameImage(FrameUtil.frameType.DESKTOP, desktop_list[i])
            new_desktop_sources_capture[i] = image_id
        }
        desktop_sources_capture = new_desktop_sources_capture
    }

    function getSourceType(the_index) {
        if (the_index < camera_sources.length) {
            return FrameUtil.frameType.CAMERA
        }
        else if (the_index < camera_sources.length+desktop_sources.length) {
            return FrameUtil.frameType.DESKTOP
        }
        else {
            return FrameUtil.frameType.WINDOW
        }
    }

    function getRealIndex(the_index) {
        if (the_index < camera_sources.length) {
            return the_index
        }
        else if (the_index < camera_sources.length+desktop_sources.length) {
            return the_index-camera_sources.length
        }
        else {
            return the_index-camera_sources.length-desktop_sources.length
        }
    }

    function _onSelect() {
        let ans = null

        if (current_select_index !== -1) {
            let source_type = getSourceType(current_select_index)
            let real_index = getRealIndex(current_select_index)
            let source_data = null
            switch (source_type) {
                case FrameUtil.frameType.WINDOW:
                    source_data = win_sources[real_index]
                    break
                case FrameUtil.frameType.DESKTOP:
                    source_data = desktop_sources[real_index]
                    break
                case FrameUtil.frameType.CAMERA:
                    source_data = camera_sources[real_index]
                    break
            }

            ans = {
                type: source_type,
                data: source_data,
            }
        }

        finish(ans)
        selectPopup.close()
        releaseCapture()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            ColumnLayout.fillWidth: true
            ColumnLayout.fillHeight: true

            Flickable {
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                contentWidth: parent.width
                contentHeight: list_container.height

                Grid {
                    id: list_container
                    width: parent.width
                    columns: parseInt((list_container.width-20)/220)
                    padding: 10

                    Rectangle {
                        width: children[0].width
                        height: children[0].height
                        border.width: current_select_index === -1 ? 1 : 0
                        border.color: Color.primary

                        ColumnLayout {
                            Rectangle {
                                id: rectangle
                                width: 200
                                height: 200/16*9
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.topMargin: 10
                                border.width: 1
                                border.color: Color.ddd

                                Icon {
                                    name: 'ban'
                                    size: 25
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            Typography {
                                ColumnLayout.fillWidth: true
                                Layout.bottomMargin: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: '无画面'
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                current_select_index = -1
                            }
                        }
                    }

                    Repeater {
                        model: (camera_sources.length+desktop_sources.length+win_sources.length)

                        delegate: Rectangle {
                            property var item: {
                                let real_index = getRealIndex(index)
                                switch (getSourceType(index)) {
                                    case FrameUtil.frameType.CAMERA:
                                        return camera_sources[real_index]
                                    case FrameUtil.frameType.DESKTOP:
                                        return desktop_sources[real_index]
                                    case FrameUtil.frameType.WINDOW:
                                        return win_sources[real_index]
                                }
                            }
                            width: children[0].width
                            height: children[0].height
                            border.width: current_select_index === index ? 1 : 0
                            border.color: Color.primary

                            ColumnLayout {
                                Rectangle {
                                    width: 200
                                    height: 200/16*9
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.topMargin: 10
                                    border.width: 1
                                    border.color: Color.ddd

                                    Icon {
                                        visible: getSourceType(index) === FrameUtil.frameType.CAMERA
                                        name: 'camera'
                                        size: 25
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Image {
                                        visible: getSourceType(index) !== FrameUtil.frameType.CAMERA
                                        anchors.fill: parent
                                        source: {
                                            if (!visible) return ''
                                            let real_index = getRealIndex(index)
                                            switch (getSourceType(index)) {
                                                case FrameUtil.frameType.DESKTOP:
                                                    return Tools.getImagePathById(desktop_sources_capture[real_index])
                                                case FrameUtil.frameType.WINDOW:
                                                    return Tools.getImagePathById(win_sources_capture[real_index])
                                            }
                                        }
                                        asynchronous: true
//                                        sourceSize.width: parent.width
//                                        sourceSize.height: parent.height
                                    }
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    spacing: 0
                                    Layout.bottomMargin: 10

                                    Typography {
                                        id: camera_type_text
                                        text: {
                                            switch (getSourceType(index)) {
                                                case FrameUtil.frameType.CAMERA:
                                                    return '[摄像头]'
                                                case FrameUtil.frameType.DESKTOP:
                                                    return '[屏幕]'
                                                case FrameUtil.frameType.WINDOW:
                                                    return '[窗口]'
                                            }
                                        }
                                        color: Color.primary
                                    }

                                    Pane {
                                        Layout.maximumWidth: 200-camera_type_text.width
                                        Layout.leftMargin: 5
                                        padding: 0
                                        background: Rectangle { opacity: 0 }

                                        Typography {
                                            width: 200-camera_type_text.width
                                            text: {
                                                let source_type = getSourceType(index)
                                                if (source_type === FrameUtil.frameType.DESKTOP) {
                                                    return '桌面'
                                                }
                                                else {
                                                    return FrameUtil.getFrameName(source_type, item)
                                                }
                                            }
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: camera_item_mouse_area
                                property bool is_hover: false
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onEntered: {
                                    is_hover = true
                                }
                                onExited: {
                                    is_hover = false
                                }
                                onClicked: {
                                    current_select_index = index
                                }
                            }

                            ToolTip {
                                visible: camera_item_mouse_area.is_hover
                                text: {
                                    let source_type = getSourceType(index)
                                    if (source_type === FrameUtil.frameType.DESKTOP) {
                                        return '桌面'
                                    }
                                    else {
                                        return FrameUtil.getFrameName(source_type, item)
                                    }
                                }
                                timeout: 3000
                                delay: 0
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {

                }
            }
        }

        Divider {
            ColumnLayout.fillWidth: true
        }

        RowLayout {
            ColumnLayout.fillWidth: true
            spacing: 0

            Item {
                RowLayout.fillWidth: true
            }

            QButton {
                variant: 'outlined'
                text: '确定'
                color: Color.primary

                onClicked: _onSelect()
            }

            QButton {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                variant: 'outlined'
                text: '取消'
                color: Color.text_secondary
                onClicked: {
                    selectPopup.close()
                    releaseCapture()
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
