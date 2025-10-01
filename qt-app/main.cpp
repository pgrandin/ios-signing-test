#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Load QML from the module's qt-project.org import path
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/HelloWorldQt6/main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
