import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1
import QtWebEngine 1.10
import "./instance_component/SystemTray"

Window {
    id: mainWindow
    width: 900
    height: 600
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: qsTr("记事本")

    // 可能是qmltype信息不全，有M16警告，这里屏蔽下
    // @disable-check M16
    onClosing: function(closeevent) {
        mainWindow.hide()
//        CloseEvent的accepted设置为false就能忽略该事件
        closeevent.accepted = false
    }

    WebEngineView {
        anchors.fill: parent
        url: "https://www.icloud.com/notes"
    }

    SystemTray {
        onShowWindow: {
            mainWindow.show()
            mainWindow.requestActivate()
        }
    }
}


/*##^##
Designer {
    D{i:0;formeditorZoom:0.9}
}
##^##*/
