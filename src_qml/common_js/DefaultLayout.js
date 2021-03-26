const DefaultLayout = [
    {
        index: 0,
        title: '单画面',
        data: [{
            left: 0,
            top: 0,
            width: 1,
            height: 1,
        }],
    },
    {
        index: 1,
        title: '大小画面',
        data: [
            {
                left: 0,
                top: 0,
                width: 1,
                height: 1,
            },
            {
                left: 0.8,
                top: 0.8,
                width: 0.2,
                height: 0.2,
                align: ['right', 'bottom'],
            },
        ]
    },
    {
        index: 2,
        title: '左右画面',
        data: [
            {
                left: 0,
                top: 0,
                width: 0.5,
                height: 1,
            },
            {
                left: 0.5,
                top: 0,
                width: 0.5,
                height: 1,
            },
        ]
    },
]
