import QtQuick 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import "../../common_component/Text/Typography"
import "../../common_js/Color.js" as Color

Pane {
    id: container
    property var data: []
    height: container.width/16*9
    padding: 0
    background: Rectangle {
        border.width: 1
        border.color: Color.ddd
    }

    Repeater {
        model: container.data ? container.data.length : 0
        delegate: Rectangle {
            property var item: container.data[index]
            width: container.width*item.width
            height: container.height*item.height
            x: container.width*item.left
            y: container.height*item.top
            border.width: 2
            border.color: Color.ddd

            Rectangle {
                id: icon_num
                width: Math.max(item.width*50, 18)
                height: Math.max(item.width*50, 18)
                x: (parent.width-icon_num.width)/2
                y: (parent.height-icon_num.height)/2
                color: Color.green
                radius: icon_num.width/2

                Text {
                    text: index+1
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Color.white
                    font.pixelSize: Math.max(item.width*25, 14)
                }
            }
        }
    }
}
