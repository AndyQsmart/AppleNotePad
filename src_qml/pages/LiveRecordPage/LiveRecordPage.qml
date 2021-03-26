import QtQuick 2.13
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import QtMultimedia 5.15
import "../../common_component/Button/QButton"
import "../../common_component/Button/MenuItem"
import "../../common_component/Button/DirectoryButton"
import "../../common_component/Divider"
import "../../common_component/Icon"
import "../../common_component/Text/Typography"
import "../../common_component/Text/Toast"
import "../../common_component/Text/OutlinedTextField"
import "../../common_component/Route"
import "../../common_component/Live/FrameUtil"
import "../../common_component/Signal/PythonSignal"
import "../../common_component/Timer/ExeOnceTimer"
import "../../instance_component/SelectLayoutDialog"
import "../../instance_component/SelectFrameDialog"
import "../../instance_component/DataProcessor/LiveRecordProcessor"
import "../../instance_component/LayoutThumbnail"
import "../../instance_component/AudioControlPanel"
import "../../instance_component/SQLTable/SettingData"
import "../../common_js/Color.js" as Color
import "../../common_js/Tools.js" as Tools
import "../../common_js/DefaultTemplate.js" as DefaultTemplate

Pane {
    id: container
    readonly property var workingState: ({
        NONE: 0,
        WORKING: 1,
        ENDING: 2,
    })
    property var working_state: workingState.NONE
    property var record_data: ({})
    property var template_id: null
    property var layout_data: null
    property var frame_data: null
    property var try_select_frame_index: null
    property var media_stream_info: ({})
    // 写缓存相关
    property var write_record_path_task_id: null
    property var write_live_path_task_id: null
    property var write_audio_volume_task_id: null

    x: 0
    y: 0
    padding: 0

    ExeOnceTimer {
        id: exe_once_timer
    }

    function writeRecordPathCache() {
        console.log('writeRecordPathCache')
        const { id } = Route.getUrlArg()
        let new_path = need_record.checked ? record_path_input.text : ''
        LiveRecordProcessor.editLiveRecord({
            id,
            save_path: new_path,
        })
    }

    function writeLivePathCache() {
        console.log('writeLivePathCache')
        const { id } = Route.getUrlArg()
        let new_path = need_live.checked ? live_url_input.text : ''
        LiveRecordProcessor.editLiveRecord({
            id,
            push_url: new_path,
        })
    }

    function writeAudioVolumeCache() {
        console.log('writeAudioVolumeCache')
        SettingData.setValue('MicAudioVolume', mic_audio_control_panel.getVolume())
        SettingData.setValue('DesktopAudioVolume', desktop_audio_control_panel.getVolume())
    }

    function changeMicAudioVolume(volume) {
        flowWindow.setMicVolume(volume)
        exe_once_timer.exe(write_audio_volume_task_id)
    }

    function changeDesktopAudioVolume(volume) {
        flowWindow.setDesktopVolume(volume)
        exe_once_timer.exe(write_audio_volume_task_id)
    }

    function changeRecordPathText() {
        exe_once_timer.exe(write_record_path_task_id)
    }

    function changeLivePathText() {
        exe_once_timer.exe(write_live_path_task_id)
    }

    function changeRecordPath(new_path) {
        const { id } = Route.getUrlArg()
        LiveRecordProcessor.editLiveRecord({
            id,
            save_path: new_path,
        })
        record_path_input.text = new_path
    }

    function onMediaStreamInfo(the_info) {
        media_stream_info = the_info
    }

    function onAudioAvgData(the_data) {
//        console.log(JSON.stringify(the_data))
        mic_audio_control_panel.setAvgVolume(the_data.mic_avg_data)
        desktop_audio_control_panel.setAvgVolume(the_data.desktop_avg_data)
    }

    function startWorking() {
        let output_list = []
        if (need_record.checked && record_path_input.text) {
            output_list.push(Tools.pathJoin(
                record_path_input.text,
                `${record_data.title}${Tools.getTimeByStamp(Tools.getTimeStamp(), '%y%MM%dd%hh%mm%ss')}.mp4`
            ))
        }
        if (need_live.checked && live_url_input.text) {
            output_list.push(live_url_input.text)
        }

        if (output_list.length === 0) {
            toast.warning('请输入录制地址或者推流地址')
            return
        }

        working_state = workingState.WORKING
        MediaTools.startMediaRecord(output_list)
    }

    function stopWorking() {
        working_state = workingState.NONE
        media_stream_info = {}
        MediaTools.stopMediaRecord()
    }

    function goBack() {
        MediaTools.stopMediaProcess()
        Route.navigateBack()
    }

    function startMediaStreamTask() {
        let the_layout_data = container.layout_data
        let the_frame_data = container.frame_data
        const { resolution, frame_rate } = record_data
        let width_height = resolution.split('x')
        MediaTools.startMediaProcess(the_frame_data, the_layout_data ? the_layout_data.data : [], {
            width: width_height[0] ? width_height[0] : 1280,
            height: width_height[1] ? width_height[1] : 720,
            frame_rate,
        })
//        PythonSignal.registerCallback(PythonSignal.signalCmd.REFRESH_MEDIA_STREAM_IMAGE, tryRefreshMediaStreamImage)
    }

    function trySelectFrame(index) {
        container.try_select_frame_index = index
        selectFrameDialog.show(container.frame_data ? container.frame_data[index] : null)
    }

    function selectFrame(data) {
        let new_frame_data = container.frame_data
        new_frame_data[container.try_select_frame_index] = data
        container.frame_data = new_frame_data
        MediaTools.setMediaData(new_frame_data, container.layout_data.data)
        LiveRecordProcessor.editLiveRecordTemplate({
            id: container.template_id,
            frame_data: JSON.stringify(new_frame_data),
        }, function(result_id, data) {
            if (result_id) {
                console.log('(LiveRecordPage.qml)editLiveRecordTemplate callback')
            }
        })
    }

    function selectLayout(data) {
//        console.log(JSON.stringify(data))
        let new_frame_data = []
        for (let i = 0; i < data.data.length; i++) {
            if (frame_data && i < frame_data.length && frame_data[i]) {
                new_frame_data.push(frame_data[i])
            }
            else {
                new_frame_data.push(null)
            }
        }
        container.layout_data = data
        container.frame_data = new_frame_data
        MediaTools.setMediaData(new_frame_data, data.data)
        LiveRecordProcessor.editLiveRecordTemplate({
            id: container.template_id,
            layout_data: JSON.stringify(data),
            frame_data: JSON.stringify(new_frame_data),
        }, function(result_id, data) {
            if (result_id) {
                console.log('(LiveRecordPage.qml)editLiveRecordTemplate callback')
            }
        })
    }

    function dealTemplateData(data) {
        console.log('(LiveRecordPage.qml)dealTemplateData', JSON.stringify(data))
        const { layout_data, frame_data } = data
        let the_layout_data = null
        try {
            the_layout_data = JSON.parse(layout_data)
        }
        catch (e) {
            the_layout_data = DefaultTemplate.DefaultTemplate[1].layout_data
        }
        let the_frame_data = null
        try {
            the_frame_data = JSON.parse(frame_data)
        }
        catch (e) {
            the_frame_data = DefaultTemplate.DefaultTemplate[1].frame_data
        }
        container.layout_data = the_layout_data
        container.frame_data = the_frame_data

        startMediaStreamTask()
    }

    function createRecordTemplate(record_id) {
        const { title } = Route.getUrlArg()
        LiveRecordProcessor.createLiveRecordTemplate({
            live_record_id: record_id,
            title,
        }, function (result_id, ans) {
            if (result_id === 0) {
                console.log("(LiveRecordPage.qml)createRecordTemplate step1", JSON.stringify(ans))
                const { data } = ans
                LiveRecordProcessor.editLiveRecord({
                    id: record_id,
                    template_id: data.id,
                }, function (result_id, ans) {
                    if (result_id === 0) {
                        console.log("(LiveRecordPage.qml)createRecordTemplate step2", JSON.stringify(ans))
                        dealTemplateData(data)
                    }
                })
                container.template_id = data.id
            }
        })
    }

    function requestRecordTemplateData(record_id, the_template_id) {
        if (the_template_id) {
            LiveRecordProcessor.getLiveRecordTemplateData({
                id: the_template_id,
            }, (result_id, ans)=>{
                if (result_id === 0) {
                    console.log('(LiveRecordPage.qml)requestRecordTemplateData', JSON.stringify(ans))
                    const { data } = ans
                    if (Tools.isNone(data)) {
                        createRecordTemplate(record_id)
                    }
                    else {
                        dealTemplateData(data)
                    }
                }
            })
        }
        else {
            createRecordTemplate(record_id)
        }
    }

    function requestRecordData() {
        const { id } = Route.getUrlArg()
        LiveRecordProcessor.getLiveRecordData({ id }, function(result_id, ans) {
            if (result_id === 0) {
                console.log("(LiveRecordPage.qml)requestRecordData", JSON.stringify(ans))
                record_data = ans.data
                const { save_path, push_url } = record_data
                need_record.checked = save_path && save_path != '' ? true : false
                record_path_input.text = save_path ? save_path : ''
                need_live.checked = push_url && push_url != '' ? true : false
                live_url_input.text = push_url ? push_url : ''
                container.template_id = record_data.template_id

                requestRecordTemplateData(record_data.id, record_data.template_id)
            }
        })
    }

    Component.onCompleted: {
        requestRecordData()
        PythonSignal.registerCallback(PythonSignal.signalCmd.REFRESH_MEDIA_STREAM_INFO, onMediaStreamInfo)
        PythonSignal.registerCallback(PythonSignal.signalCmd.AUDIO_AVG_DATA, onAudioAvgData)
        write_record_path_task_id = exe_once_timer.exeOnceAtTime(writeRecordPathCache, 1000)
        write_live_path_task_id = exe_once_timer.exeOnceAtTime(writeLivePathCache, 1000)
        write_audio_volume_task_id = exe_once_timer.exeOnceAtTime(writeAudioVolumeCache, 1000)
        SettingData.getValue('MicAudioVolume', function(value) {
            if (!Tools.isNone(value)) {
                mic_audio_control_panel.setVolume(value)
            }
        })
        SettingData.getValue('DesktopAudioVolume', function(value) {
            if (!Tools.isNone(value)) {
                desktop_audio_control_panel.setVolume(value)
            }
        })
        flowWindow.show()
    }

    Component.onDestruction: {
        PythonSignal.unregisterCallback(PythonSignal.signalCmd.REFRESH_MEDIA_STREAM_INFO, onMediaStreamInfo)
        PythonSignal.unregisterCallback(PythonSignal.signalCmd.AUDIO_AVG_DATA, onAudioAvgData)
        flowWindow.hide()
        exe_once_timer.stop()
    }

    Rectangle {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Pane {
                padding: 0
                ColumnLayout.fillWidth: true
                ColumnLayout.fillHeight: true
                background: Rectangle { }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Pane {
                        padding: 0
                        RowLayout.fillWidth: true
                        RowLayout.fillHeight: true
                        background: Rectangle { }

//                        Camera
//                        {
//                            id: camera;
//                        }

//                        VideoOutput
//                        {
//                            source: camera
//                            anchors.fill: parent
//                            focus : visible // to receive focus and capture key events when visible
//                        }

                        VideoOutput {
                            anchors.fill: parent
//                            anchors.top: parent.top
//                            anchors.bottom: parent.bottom
//                            width: parent.width
                            source: MediaFrameProvider
                        }
                    }

                    Rectangle {
                        width: 1
                        RowLayout.fillHeight: true
                        color: Color.ddd
                    }

                    Pane {
                        width: 300
                        padding: 0
                        RowLayout.fillHeight: true
                        background: Rectangle { }

                        Flickable {
                            anchors.fill: parent
                            clip: true
                            flickableDirection: Flickable.VerticalFlick
                            contentWidth: parent.width
                            contentHeight: setting_container.height

                            ColumnLayout {
                                id: setting_container
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    spacing: 0
                                    ColumnLayout.fillWidth: true

                                    CheckBox {
                                        id: need_record
                                        onCheckedChanged: writeRecordPathCache()
                                    }

                                    Typography {
                                        text: qsTr('录制文件')
                                    }
                                }

                                RowLayout {
                                    visible: need_record.checked
                                    Layout.rightMargin: 10
                                    Layout.leftMargin: 10
                                    spacing: 0
                                    ColumnLayout.fillWidth: true

                                    OutlinedTextField {
                                        id: record_path_input
                                        RowLayout.fillWidth: true
                                        placeholder: '文件保存路径'
                                        onTextChanged: changeRecordPathText()
                                    }

                                    DirectoryButton {
                                        text: qsTr('选择路径')
                                        Layout.leftMargin: 10
                                        variant: 'outlined'
                                        color: Color.text_secondary
                                        onChange: changeRecordPath(url)
                                    }
                                }

                                RowLayout {
                                    spacing: 0
                                    ColumnLayout.fillWidth: true

                                    CheckBox {
                                        id: need_live
                                        onCheckedChanged: writeLivePathCache()
                                    }

                                    Typography {
                                        text: qsTr('推流地址')
                                    }
                                }

                                OutlinedTextField {
                                    id: live_url_input
                                    visible: need_live.checked
                                    Layout.rightMargin: 10
                                    Layout.leftMargin: 10
                                    Layout.bottomMargin: 10
                                    ColumnLayout.fillWidth: true
                                    placeholder: '推流地址'
                                    onTextChanged: changeLivePathText()
                                }

                                Divider {
                                    ColumnLayout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 0
                                    ColumnLayout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.topMargin: 10

                                    Typography {
                                        text: `分辨率：${record_data.resolution}`
                                    }
                                    Typography {
                                        Layout.leftMargin: 20
                                        text: `帧率：${record_data.frame_rate}`
                                    }
                                }

                                Typography {
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.topMargin: 20
                                    text: '模板'
                                }

                                Pane {
                                    background: Rectangle {
                                        border.width: 1
                                        border.color: Color.ddd
                                    }

                                    padding: 0
                                    ColumnLayout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.bottomMargin: 10

                                    ColumnLayout {
                                        width: parent.width
                                        spacing: 0

                                        Typography {
                                            Layout.leftMargin: 10
                                            Layout.rightMargin: 10
                                            Layout.topMargin: 10
                                            text: '布局'
                                        }

                                        QButton {
                                            visible: layout_data ? false : true
                                            text: '选择'
                                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                            variant: 'outlined'
                                            color: Color.text_secondary

                                            onClicked: {
                                                selectLayoutDialog.show()
                                            }
                                        }

                                        LayoutThumbnail {
                                            visible: layout_data ? true : false
                                            width: 200
                                            Layout.leftMargin: (parent.width-200)/2
//                                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                            data: layout_data ? layout_data.data : null

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: {
                                                    selectLayoutDialog.show(layout_data.index, layout_data.id)
                                                }
                                            }
                                        }

                                        Typography {
                                            Layout.leftMargin: 10
                                            Layout.rightMargin: 10
                                            Layout.topMargin: 10
                                            Layout.bottomMargin: 10
                                            text: '画面'
                                        }

                                        Typography {
                                            visible: container.frame_data ? false : true
                                            Layout.bottomMargin: 10
                                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                            text: '请选择布局'
                                            color: Color.text_secondary
                                        }

                                        Repeater {
                                            model: container.frame_data ? container.frame_data.length : 0

                                            delegate: Pane {
                                                property var item: container.frame_data[index]

                                                topPadding: 0
                                                bottomPadding: 10
                                                leftPadding: 20
                                                rightPadding: 10
                                                background: Rectangle { opacity: 0 }

                                                ColumnLayout {
                                                    spacing: 0

                                                    RowLayout {
                                                        spacing: 0

                                                        Typography {
                                                            text: '画面'
                                                        }
                                                        Rectangle {
                                                            Layout.leftMargin: 10
                                                            width: 26
                                                            height: 26
                                                            radius: 13
                                                            color: Color.green

                                                            Text {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                font.pixelSize: 20
                                                                color: Color.white
                                                                text: index+1
                                                            }
                                                        }
                                                        QButton {
                                                            Layout.leftMargin: 10
                                                            text: '选择'
                                                            variant: 'outlined'
                                                            color: Color.text_secondary

                                                            onClicked: trySelectFrame(index)
                                                        }
                                                    }

                                                    Typography {
                                                        visible: Tools.isNone(item) ? false : true
                                                        text: Tools.isNone(item) ? '' : FrameUtil.getFrameName(item.type, item.data)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ScrollBar.vertical: ScrollBar {

                            }
                        }
                    }
                }
            }

            Divider {
                ColumnLayout.fillWidth: true
            }

            RowLayout {
                spacing: 0
                ColumnLayout.fillWidth: true

                Item {
                    width: 110
                    height: children[0].height
                    Layout.bottomMargin: 5
                    Layout.topMargin: 5
                    Layout.leftMargin: 10

                    Typography {
                        variant: 'overline'
                        text: `帧率：${media_stream_info.fps ? media_stream_info.fps : 0}fps`
                    }
                }
                Item {
                    width: 200
                    height: children[0].height
                    Layout.leftMargin: 10

                    Typography {
                        variant: 'overline'
                        text: `录制时间：${media_stream_info.duration ? Tools.getSecondTimeByStamp(media_stream_info.duration, '%hh:%mm:%ss') : '00:00:00'}`
                    }
                }
//                Item {
//                    width: 180
//                    height: children[0].height
//                    Layout.leftMargin: 10

//                    Typography {
//                        variant: 'overline'
//                        text: '码率：0kb/s'
//                    }
//                }
                Item {
                    width: 160
                    height: children[0].height
                    Layout.leftMargin: 10

                    Typography {
                        variant: 'overline'
                        text: `编码速度：${media_stream_info.speed ? media_stream_info.speed : 0}x`
                    }
                }
                Typography {
                    visible: false
                    Layout.leftMargin: 10
                    variant: 'overline'
                    text: '处理压力过大,请降低分辨率或帧率'
                    color: Color.secondary
                }
            }

            Divider {
                ColumnLayout.fillWidth: true
            }

            RowLayout {
                spacing: 0
                ColumnLayout.fillWidth: true

                AudioControlPanel {
                    id: mic_audio_control_panel
                    title: '麦克风'
                    onChange: changeMicAudioVolume(volume)

                    Connections {
                        target: flowWindow
                        function onMicAudioMute() {
                            mic_audio_control_panel.mute()
                        }
                    }
                }
                AudioControlPanel {
                    id: desktop_audio_control_panel
                    title: '系统声音'
                    onChange: changeDesktopAudioVolume(volume)

                    Connections {
                        target: flowWindow
                        function onDesktopAudioMute() {
                            desktop_audio_control_panel.mute()
                        }
                    }
                }

                Switch {
                    checked: true
                    Layout.leftMargin: 10
                    onCheckedChanged: {
                        if (checked) {
                            flowWindow.show()
                        }
                        else {
                            flowWindow.hide()
                        }
                    }
                }
                Typography {
                    text: '浮窗'
                }

                Item {
                    RowLayout.fillWidth: true
                }
                QButton {
                    visible: working_state === workingState.NONE
                    variant: 'contained'
                    text: qsTr("开始直播")
                    color: Color.primary
                    text_color: Color.white
                    onClicked: startWorking()
                }
                QButton {
                    visible: working_state === workingState.NONE
                    Layout.bottomMargin: 10
                    Layout.topMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    variant: 'contained'
                    text: qsTr("返回")
                    text_color: Color.text_primary
                    onClicked: goBack()
                }
                QButton {
                    visible: working_state === workingState.WORKING
                    Layout.bottomMargin: 10
                    Layout.topMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    variant: 'contained'
                    text: qsTr("结束")
                    color: Color.secondary
                    text_color: Color.white
                    onClicked: stopWorking()
                }
            }
        }
    }

    SelectLayoutDialog {
        id: selectLayoutDialog
        x: 0
        y: 0
        width: parent.width
        height: parent.height

        onFinish: selectLayout(data)
    }

    SelectFrameDialog {
        id: selectFrameDialog
        x: 0
        y: 0
        width: parent.width
        height: parent.height

        onFinish: selectFrame(data)
    }

    Toast {
        id: toast
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
