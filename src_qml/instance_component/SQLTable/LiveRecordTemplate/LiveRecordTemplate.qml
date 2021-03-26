import QtQuick 2.0
import "../TableBase"
import "../../../common_component/SQL/SQLHelper"
import "../../../common_js/Tools.js" as Tools

TableBase {
    table_name: 'LiveRecordTemplate'
    table_field: ({
        live_record_id: 'TEXT',
        title: 'TEXT',
        layout_data: 'TEXT',
        frame_data: 'TEXT',
    })

    function getTemplateById(id, callback) {
        let query = getTable().all().filter('id', '=', id)
        query.list(null, (data)=>{
            if (data.length === 0) {
                callback(null)
            }
            else {
                callback(data[0])
            }
        })
    }
}
