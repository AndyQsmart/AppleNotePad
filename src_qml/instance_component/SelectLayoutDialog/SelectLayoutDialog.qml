import QtQuick 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import "../../common_component/Text/Typography"
import "../../common_component/Button/QButton"
import "../../common_component/Divider"
import "../../common_js/Color.js" as Color
import "../../common_js/Tools.js" as Tools
import "../../common_js/DefaultLayout.js" as DefaultLayout
import "../LayoutThumbnail"

Popup {
    id: selectPopup
    property int curent_select_index: 0
    property var curent_select_id: null
    signal finish(var data)

    visible: false
    padding: 0

    function show(index=null, id=null) {
        curent_select_index = Tools.isNone(index) ? -1 : index
        curent_select_id = null

        if (curent_select_index == -1 && !curent_select_id) {
            curent_select_index = 0
        }

        selectPopup.open()
    }

    function _onSelect() {
        if (!Tools.isNone(curent_select_index)) {
            let item = DefaultLayout.DefaultLayout[curent_select_index]
            let ans = {
                index: curent_select_index,
                title: item.title,
                data: item.data,
            }
            finish(ans)
            selectPopup.close()
        }
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
                    columns: parseInt((list_container.width-20)/220)
                    padding: 10

                    Repeater {
                        id: list_repeater
                        model: DefaultLayout.DefaultLayout.length
                        delegate: Rectangle {
                            property var item: DefaultLayout.DefaultLayout[index]
                            width: children[0].width
                            height: children[0].height
                            border.width: curent_select_index === index ? 1 : 0
                            border.color: Color.primary

                            ColumnLayout {
                                LayoutThumbnail {
                                    width: 200
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.topMargin: 10
                                    data: item.data
                                }

                                Typography {
                                    ColumnLayout.fillWidth: true
                                    Layout.bottomMargin: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: item.title
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    curent_select_index = index
                                }
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
