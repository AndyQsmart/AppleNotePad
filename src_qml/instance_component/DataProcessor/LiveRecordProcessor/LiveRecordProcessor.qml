pragma Singleton

import QtQuick 2.0
import "../../SQLTable/LiveRecord"
import "../../SQLTable/LiveRecordTemplate"
import "../../../common_js/Tools.js" as Tools

Item {
    LiveRecord {
        id: live_record_sql
    }

    LiveRecordTemplate {
        id: live_record_template_sql
    }

    function createLiveRecord(arg, callback) {
        console.log('(LiveRecordProcessor.qml)createLiveRecord', JSON.stringify(arg))
        let ans = live_record_sql.create(arg)
        console.log('(LiveRecordProcessor.qml)createLiveRecord success', JSON.stringify(ans))
        if (callback) {
            callback(0)
        }
    }

    function editLiveRecord(arg, callback) {
        console.log('(LiveRecordProcessor.qml)editLiveRecord', JSON.stringify(arg))
        const {
            id, title, start_time_stamp, end_time_stamp, save_path, push_url, template_id,
            resolution, frame_rate,
        } = arg
        live_record_sql.getLiveRecordById(id, function(data) {
            if (!Tools.isNone(title)) {
                data.title = title
            }
            if (!Tools.isNone(start_time_stamp)) {
                data.start_time_stamp = start_time_stamp
            }
            if (!Tools.isNone(end_time_stamp)) {
                data.end_time_stamp = end_time_stamp
            }
            if (!Tools.isNone(save_path)) {
                data.save_path = save_path
            }
            if (!Tools.isNone(push_url)) {
                data.push_url = push_url
            }
            if (!Tools.isNone(template_id)) {
                data.template_id = template_id
            }
            if (!Tools.isNone(resolution)) {
                data.resolution = resolution
            }
            if (!Tools.isNone(frame_rate)) {
                data.frame_rate = frame_rate
            }
            live_record_sql.save()
            if (callback) {
                callback(0, {
                    data,
                })
            }
        })
    }

    function getLiveRecordData(arg, callback) {
        console.log('(LiveRecordProcessor.qml)getLiveRecordData', JSON.stringify(arg))
        const { id } = arg
        live_record_sql.getLiveRecordById(id, function (data) {
            if (callback) {
                callback(0, {
                    data,
                })
            }
        })
    }

    function getLiveRecordList(arg, index_from, index_to, callback) {
//        console.log(JSON.stringify(arg))
        live_record_sql.getLiveRecordByAdvanceSearch(arg, index_from, index_to, function (all_count, task_list) {
            if (callback) {
                callback(0, {
                    all_count,
                    task_list,
                })
            }
        })
    }

    function deleteLiveRecord(arg, callback) {
        console.log('(LiveRecordProcessor.qml)deleteLiveRecord', JSON.stringify(arg))
        const { id } = arg
        live_record_sql.deleteLiveRecordById(id, function(data) {
            if (callback) {
                callback(0)
            }
        })
    }

    function createLiveRecordTemplate(arg, callback) {
        let ans = live_record_template_sql.create(arg)
        if (callback) {
            callback(0, {
                data: ans,
            })
        }
    }

    function getLiveRecordTemplateData(arg, callback) {
        console.log('(LiveRecordProcessor.aml)getLiveRecordTemplateData', JSON.stringify(arg))
        const { id } = arg
        live_record_template_sql.getTemplateById(id, function (data) {
            if (callback) {
                callback(0, {
                    data,
                })
            }
        })
    }

    function editLiveRecordTemplate(arg, callback) {
        console.log('(LiveRecordProcessor.qml)editLiveRecordTemplate', JSON.stringify(arg))
        const { id, title, layout_data, frame_data } = arg
        live_record_template_sql.getTemplateById(id, function (data) {
            if (!Tools.isNone(title)) {
                data.title = title
            }
            if (!Tools.isNone(layout_data)) {
                data.layout_data = layout_data
            }
            if (!Tools.isNone(frame_data)) {
                data.frame_data = frame_data
            }
            live_record_template_sql.save()
            if (callback) {
                callback(0, {
                    data,
                })
            }
        })
    }
}
