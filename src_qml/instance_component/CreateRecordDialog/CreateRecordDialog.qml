import QtQuick 2.13
import QtQuick.Controls.Material 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import QtQuick.Window 2.14
import "../../common_component/Icon"
import "../../common_component/Text/Typography"
import "../../common_component/Text/OutlinedTextField"
import "../../common_component/Text/Toast"
import "../../common_component/Button/QButton"
import "../../common_component/Button/DirectoryButton"
import "../../common_component/Picker/TimePicker"
import "../../common_js/StringUtil.js" as Strings
import "../../common_js/Color.js" as Color
import "../../common_js/Tools.js" as Tools
import "../../common_component/Text/Typography/FontSize.js" as FontSize
import "../../instance_component/DataProcessor/LiveRecordProcessor"

Popup {
    id: createPopup
    property var defaultResolution: [
        '1280x720',
        '1920x1080',
    ]

    property var defaultFrameRate: [
        '30',
        '60',
    ]
    property var edit_id: null

    width: 600
    height: 580
    padding: 20
    visible: false
    modal: true
//    focus: true
    closePolicy: Popup.NoAutoClose
    signal finish(var id)

    function requestData(id) {
        if (!id) {
            title_input.text = ''
            let now_time = new Date()
            start_time_input.setValue(now_time)
            end_time_input.setValue(now_time)
            need_record.checked = false
            save_path_input.text = ''
            size_input.currentIndex = 0
            frame_rate_input.currentIndex = 0
            return
        }
        LiveRecordProcessor.getLiveRecordData({
            id,
        }, function (result_id, ans) {
            if (result_id === 0) {
                console.log('(CreateDialog.qml)requestData: ans', JSON.stringify(ans))
                const { data } = ans
                const { title, start_time_stamp, end_time_stamp, save_path, resolution, frame_rate } = data
                title_input.text = title
                start_time_input.setValue(Tools.getDateByStamp(start_time_stamp))
                end_time_input.setValue(Tools.getDateByStamp(end_time_stamp))
                need_record.checked = save_path && save_path != '' ? true : false
                save_path_input.text = save_path ? save_path : ''
                let size_input_index = defaultResolution.indexOf(resolution)
                size_input.currentIndex = size_input_index === -1 ? size_input.model.length-1 : size_input_index
                custom_size_input.text = resolution
                let frame_rate_input_index = defaultFrameRate.indexOf(frame_rate)
                frame_rate_input.currentIndex = frame_rate_input_index === -1 ? 0 : frame_rate_input_index
            }
        })
    }

    function show(id) {
        createPopup.open()
        edit_id = id
        requestData(id)
    }

    function createLiveRecord() {
        console.log('(CreateRecordDialog.qml)createLiveRecord')
        let title_text = title_input.text
        let start_time = start_time_input.value
        let end_time = end_time_input.value
        let save_path = save_path_input.text
        let size = size_input.currentIndex
        let frame_rate = frame_rate_input.currentIndex
        console.log(start_time)

        if (!title_text) {
            toast.warning(qsTr("请输入名称"))
            return
        }

        if (start_time > end_time) {
            toast.warning(qsTr("开始时间应早于结束时间"))
            return
        }

        if (size_input.currentIndex === size_input.model.length-1) {
            let size_text = custom_size_input.text
            if (!/^[0-9]+x[0-9]+$/.test(size_text)) {
                toast.warning(qsTr("请输入正确的分辨率"))
                return
            }
            let width_height = size_text.split('x')
            if (width_height[0] < 10) {
                toast.warning(qsTr("分辨率宽度需大于10"))
                return
            }
            if (width_height[1] < 10) {
                toast.warning(qsTr("分辨率高度需大于10"))
                return
            }
            if (width_height[0] > 18000) {
                toast.warning(qsTr("分辨率宽度需小于18000"))
                return
            }
            if (width_height[1] > 18000) {
                toast.warning(qsTr("分辨率高度需小于18000"))
                return
            }
        }

        if (edit_id) {
            LiveRecordProcessor.editLiveRecord({
                id: edit_id,
                title: title_text,
                time_stamp: Tools.getTimeStamp(),
                start_time_stamp: Tools.getTimeStampByDate(start_time),
                end_time_stamp: Tools.getTimeStampByDate(end_time),
                save_path: need_record.checked ? save_path_input.text : '',
                resolution: size_input.currentIndex === size_input.model.length-1 ? custom_size_input.text : size_input.currentText,
                frame_rate: frame_rate_input.currentText,
            }, function (result_id) {
                 if (result_id === 0) {
                     createPopup.close()
                     finish(edit_id)
                 }
            })
        }
        else {
            LiveRecordProcessor.createLiveRecord({
                title: title_text,
                time_stamp: Tools.getTimeStamp(),
                start_time_stamp: Tools.getTimeStampByDate(start_time),
                end_time_stamp: Tools.getTimeStampByDate(end_time),
                save_path: need_record.checked ? save_path_input.text : '',
                resolution: size_input.currentIndex === size_input.model.length-1 ? custom_size_input.text : size_input.currentText,
                frame_rate: frame_rate_input.currentText,
            }, function (result_id) {
                 if (result_id === 0) {
                     createPopup.close()
                     finish(null)
                 }
            })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            ColumnLayout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            spacing: 0

            Typography {
                text: qsTr(edit_id ? "修改直播任务" : "新建直播任务")
                RowLayout.fillWidth: true
            }

            MouseArea {
                width: 32
                height: 32
                cursorShape: Qt.PointingHandCursor

                Icon {
                    name: 'close'
                    size: 20
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                onClicked: {
                    createPopup.close()
                }
            }
        }

        ColumnLayout {
            spacing: 10.1
            Layout.topMargin: 20
            ColumnLayout.fillWidth: true
            ColumnLayout.fillHeight: true

            RowLayout {
                RowLayout.fillWidth: true

                Typography {
                    wrapMode: Text.WrapAnywhere
                    text: qsTr('名称：')
                }

                OutlinedTextField {
                    id: title_input
                    RowLayout.fillWidth: true
                }
            }

            RowLayout {
                RowLayout.fillWidth: true

                Typography {
                    wrapMode: Text.WrapAnywhere
                    text: qsTr('开始时间：')
                }

                TimePicker {
                    id: start_time_input
                }

                Item {
                    RowLayout.fillWidth: true
                    height: 10
                }
            }

            RowLayout {
                RowLayout.fillWidth: true

                Typography {
                    wrapMode: Text.WrapAnywhere
                    text: qsTr('结束时间：')
                }

                TimePicker {
                    id: end_time_input
                }

                Item {
                    RowLayout.fillWidth: true
                    height: 10
                }
            }

            RowLayout {
                RowLayout.fillWidth: true

                CheckBox {
                    id: need_record
                }

                Typography {
                    wrapMode: Text.WrapAnywhere
                    text: qsTr('录制文件')
                }
            }

            RowLayout {
                visible: need_record.checked
                RowLayout.fillWidth: true

                OutlinedTextField {
                    id: save_path_input
                    RowLayout.fillWidth: true
                    placeholder: '文件保存路径'
                }

                DirectoryButton {
                    text: qsTr('选择路径')
                    variant: 'outlined'
                    color: Color.text_secondary
                    onChange: {
                        save_path_input.text = url
                    }
                }
            }

            RowLayout {
                RowLayout.fillWidth: true

                Typography {
                    wrapMode: Text.WrapAnywhere
                    text: qsTr('分辨率：')
                }

                Row {
                    width: 200

                    ComboBox {
                        id: size_input
                        width: parent.width
                        model: [].concat(defaultResolution).concat(['自定义'])
                        font.pointSize: FontSize.body2
                    }
                }

                Row {
                    visible: size_input.currentIndex === size_input.model.length-1
                    width: 250
                    Layout.leftMargin: 10

                    onVisibleChanged: {
                        if (visible) {
                            custom_size_input.text = '1280x720'
                            custom_size_input.last_text = custom_size_input.text
                        }
                    }

                    OutlinedTextField {
                        property string last_text: ''
                        id: custom_size_input
                        width: parent.width

                        onTextChanged: {
                            let current_text = custom_size_input.text
                            if (/^[0-9]*x[0-9]*$/.test(current_text)) {
                                last_text = current_text
                                return
                            }
                            if (current_text.indexOf('x') === -1 && last_text.indexOf('x') === -1) {
                                custom_size_input.text = '1280x720'
                                last_text = custom_size_input.text
                            }
                            else {
                                custom_size_input.text = last_text
                            }
                        }
                    }
                }
            }

            RowLayout {
                RowLayout.fillWidth: true

                Typography {
                    wrapMode: Text.WrapAnywhere
                    text: qsTr('帧率：')
                }

                ComboBox {
                    id: frame_rate_input
                    model: defaultFrameRate
                    font.pointSize: FontSize.body2
                }
            }

            Item {
                ColumnLayout.fillHeight: true
            }
        }

        RowLayout {
            Item {
                RowLayout.fillWidth: true
            }

            QButton {
                text: qsTr(edit_id ? '修改' : '创建')
                variant: 'outlined'
                color: Color.primary
                onClicked: createLiveRecord()
            }
            QButton {
                text: qsTr('取消')
                Layout.leftMargin: 10
                variant: 'outlined'
                color: Color.text_secondary
                onClicked: {
                    createPopup.close()
                }
            }
        }
    }

    Toast {
        id: toast
    }
}
