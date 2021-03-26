#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFont>
//#include <windows.h>
#include "src/window_capture/window_capture.h"
#include "src/image_util/image_provider.h"
#include "src/image_util/image_tools.h"
#include "src/media_stream/media_tools.h"
#include "src/media_stream/media_frame_provider.h"
#include "src/utils/qml_signal.h"

//long __stdcall  callback(_EXCEPTION_POINTERS *excp) {
//    CCrashStack crashStack(excp);
//    QString sCrashInfo = crashStack.GetExceptionInfo();
//    QString sFileName = "testcrash.log";

//    QFile file(sFileName);
//    if (file.open(QIODevice::WriteOnly|QIODevice::Truncate))
//    {
//        file.write(sCrashInfo.toUtf8());
//        file.close();
//    }

//    qDebug()<<"Error:\n"<<sCrashInfo;
//    //MessageBox(0,L"Error",L"error",MB_OK);
//    QMessageBox msgBox;
//    msgBox.setText(QString::fromUtf8("亲，我死了，重新启动下吧！"));
//    msgBox.exec();

//    return   EXCEPTION_EXECUTE_HANDLER;
//}


int main(int argc, char *argv[]) {
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    // 高分辨率适配
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
#endif

    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Material");
    QFont defualt_font;
    defualt_font.setFamily("Arial");
    app.setFont(defualt_font);
    app.setOrganizationName("Zhibing");
    app.setOrganizationDomain("www.jiuzhangzaixian.com");

    QQmlApplicationEngine engine;
    // 窗口、桌面、摄像头获取相关
    WindowCapture window_capture;
    engine.rootContext()->setContextProperty("WindowCapture", &window_capture);
    // 视频流相关
    MediaTools media_tools;
    engine.rootContext()->setContextProperty("MediaTools", &media_tools);
    engine.rootContext()->setContextProperty("MediaFrameProvider", MediaFrameProvider::instance());
    // 图片传递相关
    ImageTools image_tools;
    engine.rootContext()->setContextProperty("ImageTools", &image_tools);
    ImageProvider image_provider;
    engine.addImageProvider(QString("image_provider"), &image_provider);
    // 信号相关
    engine.rootContext()->setContextProperty("QMLSignal", QMLSignal::instance());

    const QUrl url(QStringLiteral("qrc:/src_qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}
