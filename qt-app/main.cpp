#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

int main(int argc, char *argv[])
{
    qDebug() << "Qt6 App Starting...";
    QGuiApplication app(argc, argv);
    qDebug() << "QGuiApplication created";

    QQmlApplicationEngine engine;
    qDebug() << "QQmlApplicationEngine created";

    // Try loading QML
    QUrl qmlUrl(QStringLiteral("qrc:/qt/qml/HelloWorldQt6/main.qml"));
    qDebug() << "Loading QML from:" << qmlUrl;

    engine.load(qmlUrl);

    qDebug() << "QML loaded, root objects count:" << engine.rootObjects().size();

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "ERROR: No root objects found!";
        return -1;
    }

    qDebug() << "Starting event loop...";
    return app.exec();
}
