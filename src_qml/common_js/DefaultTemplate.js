.import "./DefaultLayout.js" as DefaultLayout

const DefaultTemplate = [
    {
        title: '默认1',
        layout_data: Object.assign({
            // id 用于layout
            // index: 0, // default的index
            // title: 
            // data:
        }, DefaultLayout.DefaultLayout[0]),
        frame_data: [
            null,
        ],
    },
    {
        title: '默认2',
        layout_data: Object.assign({
            index: 1,
        }, DefaultLayout.DefaultLayout[1]),
        frame_data: [
            null,
            null,
        ],
    },
]
