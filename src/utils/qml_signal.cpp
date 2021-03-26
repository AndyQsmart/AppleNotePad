#include "qml_signal.h"

QMLSignal *QMLSignal::_instance = nullptr;

QMLSignal *QMLSignal::instance() {
    if (!QMLSignal::_instance) {
        QMLSignal::_instance = new QMLSignal();
    }
    return QMLSignal::_instance;
}

void QMLSignal::emitSignal(QMLSignalCMD cmd, QVariant data) {
    emit qmlSignal((int)cmd, data);
}
