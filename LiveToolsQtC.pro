QT += quick
QT += quickcontrols2
QT += gui
QT += core
QT += multimedia

LIBS += -lgdi32 -ldwmapi

# ffmpeg
win32 {
    INCLUDEPATH += $$PWD/lib/ffmpeg/include

    PRE_TARGETDEPS += $$PWD/lib/ffmpeg/lib/libavcodec.dll.a \
        $$PWD/lib/ffmpeg/lib/libavdevice.dll.a \
        $$PWD/lib/ffmpeg/lib/libavfilter.dll.a \
        $$PWD/lib/ffmpeg/lib/libavformat.dll.a \
        $$PWD/lib/ffmpeg/lib/libavutil.dll.a \
        $$PWD/lib/ffmpeg/lib/libswresample.dll.a \
        $$PWD/lib/ffmpeg/lib/libswscale.dll.a

    LIBS += -L$$PWD/lib/ffmpeg/lib/ \
        -llibavcodec.dll \
        -llibavdevice.dll \
        -llibavfilter.dll \
        -llibavformat.dll \
        -llibavutil.dll \
        -llibswresample.dll \
        -llibswscale.dll
}

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        main.cpp \
        src/image_util/image_pool.cpp \
        src/image_util/image_provider.cpp \
        src/image_util/image_tools.cpp \
        src/media_stream/media_frame_provider.cpp \
        src/media_stream/media_graber/camera_grabber.cpp \
        src/media_stream/media_graber/window_grabber.cpp \
        src/media_stream/media_process_thread.cpp \
        src/media_stream/media_tools.cpp \
        src/utils/ffmpeg_util.cpp \
        src/utils/qml_signal.cpp \
        src/window_capture/helper.cpp \
        src/window_capture/window_capture.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    src/image_util/image_pool.h \
    src/image_util/image_provider.h \
    src/image_util/image_tools.h \
    src/media_stream/media_frame_provider.h \
    src/media_stream/media_graber/camera_grabber.h \
    src/media_stream/media_graber/window_grabber.h \
    src/media_stream/media_process_thread.h \
    src/media_stream/media_tools.h \
    src/utils/ffmpeg_util.h \
    src/utils/qml_signal.h \
    src/window_capture/helper.h \
    src/window_capture/window_capture.h
