import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import "../../common_component/Text/Typography"
import "../../common_component/Icon"
import "../../common_js/Color.js" as Color

Window {
    id: container
    property var mic_volume: 0.7
    property var desktop_volume: 0.7
    signal micAudioMute()
    signal desktopAudioMute()

    width: 140
    height: 76
    color: "#00000000"
    visible: true
    transientParent: null
    flags: Qt.FramelessWindowHint | Qt.WindowSystemMenuHint | Qt.WindowStaysOnTopHint | Qt.X11BypassWindowManagerHint

//    onTransientParentChanged: {
//        console.log(flowWindow.transientParent)
//    }

    function setMicVolume(volume) {
        mic_volume = volume
    }

    function setDesktopVolume(volume) {
        desktop_volume = volume
    }

    Component.onCompleted: {
        if (container.transientParent != null) {
            container.transientParent = null
            container.x = Screen.desktopAvailableWidth-container.width-30
            container.y = Screen.desktopAvailableHeight-container.height-30
        }
    }

    Rectangle {
        x: 0
        y: 0
        width: parent.width
        height: parent.height
        radius: 10
        color: '#EEF4FE'
        border.color: Color.primary
        border.width: 1

        MouseArea {
            id: dragRegion
            anchors.fill: parent
            property point clickPos: Qt.point(0, 0)
            onPressed: {
                clickPos = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: {
                //鼠标偏移量
                let delta = Qt.point(mouse.x-clickPos.x, mouse.y-clickPos.y)
                //如果mainwindow继承自QWidget,用setPos
                container.setX(container.x+delta.x)
                container.setY(container.y+delta.y)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.topMargin: 10
                Layout.leftMargin: 10

                Item {
                    width: 25
                    height: children[0].height

                    Icon {
                        name: mic_volume == 0 ? 'volume-off' : 'volume-up'
                        color: mic_volume == 0 ? Color.secondary : Color.black
                        size: 15
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: micAudioMute()
                    }
                }
                Item {
                    width: 28

                    Typography {
                        anchors.fill: parent
                        variant: 'little'
                        color: mic_volume == 0 ? Color.secondary : Color.primary
                        text: `${parseInt(mic_volume*100)}%`
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Typography {
                    text: '麦克风'
                }
            }

            Item {
                ColumnLayout.fillHeight: true
            }

            RowLayout {
                Layout.bottomMargin: 10
                Layout.leftMargin: 10

                Item {
                    width: 25
                    height: children[0].height

                    Icon {
                        name: desktop_volume == 0 ? 'volume-off' : 'volume-up'
                        color: desktop_volume == 0 ? Color.secondary : Color.black
                        size: 15
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: desktopAudioMute()
                    }
                }
                Item {
                    width: 28

                    Typography {
                        anchors.fill: parent
                        variant: 'little'
                        color: desktop_volume == 0 ? Color.secondary : Color.primary
                        text: `${parseInt(desktop_volume*100)}%`
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Typography {
                    text: '系统音'
                }
            }
        }
    }
}
