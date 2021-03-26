import QtQuick 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import "../../common_js/Color.js" as Color
import "../../common_component/Text/Typography"
import "../../common_component/Icon"

Pane {
    id: container
    property var title: ''
    property var default_value: 0.7
    property var value: default_value
    property var last_value: default_value
    property var avg_volume: 0
    signal change(var volume)

    background: Rectangle { }

    function getVolume() {
        return value
    }

    function setVolume(volume) {
        slider.value = volume
        container.value = volume
        container.last_value = volume
        change(volume)
    }

    function setAvgVolume(volume) {
        let db_value = 20*Math.log10(volume/65536)
        if (db_value < -60) {
            db_value = -60.0
        }
        if (db_value > 0) {
            db_value = 0.0
        }
        let percent = (db_value+60)/60.0
        container.avg_volume =  Math.floor(10*percent+0.5)
    }

    function mute() {
        let to_value = 0.7
        if (container.value == 0) {
            if (container.last_value != 0) {
                to_value = container.last_value
            }
            container.last_value = to_value
        }
        else {
            to_value = 0
        }
        container.value = to_value
        slider.value = to_value
        change(container.value)
    }

    ColumnLayout {
        spacing: 0

        RowLayout {
            Typography {
                variant: 'overline'
                text: title
            }

            Rectangle {
                width: 30
                height: 20

                RowLayout {
                    spacing: 0
                    anchors.fill: parent
                    visible: container.value == 0

                    Icon {
                        size: 13
                        name: 'volume-off'
                        Layout.fillHeight: true
                        color: Color.secondary
                    }
                    Typography {
                        text: 'x'
                        color: Color.secondary
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillHeight: true
                    }
                }

                Icon {
                    visible: container.value != 0
                    size: 13
                    name: 'volume-up'
                    Layout.fillHeight: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mute()
                }
            }

            Item {
                width: 150
                Layout.fillHeight: true

                Slider {
                    id: slider
                    anchors.fill: parent
                    stepSize: 0.01
                    to: 1
                    value: default_value
                    ToolTip.text: qsTr(`${parseInt(slider.value * 100)}%`)
                    ToolTip.visible: hovered
                    ToolTip.timeout: 3000
                    ToolTip.delay: 0

                    onMoved: {
                        container.value = slider.value
                        container.last_value = slider.value
                        change(container.value)
                    }
                }
            }
        }

        RowLayout {
            spacing: 2
            Layout.topMargin: 10

            Repeater {
                model: 10
                delegate: Rectangle {
                    width: 23
                    height: 4
                    border.width: 2
                    border.color: index < avg_volume ? Color.greenyellow : Color.ddd
                }
            }
        }
    }
}
