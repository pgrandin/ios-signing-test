#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtPlugin>
#include <QDebug>

// Statically import the iOS platform plugin
Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)

int main(int argc, char *argv[])
{
    qDebug() << "Qt6 App Starting...";

    QGuiApplication app(argc, argv);
    qDebug() << "QGuiApplication created successfully!";

    QQmlApplicationEngine engine;

    // Load QML from Qt resource system (qt_add_qml_module)
    const QUrl url(QStringLiteral("qrc:/qt/qml/HelloWorldApp/main.qml"));
    qDebug() << "Loading QML from:" << url;

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "ERROR: Failed to load QML from" << url;
        return -1;
    }

    qDebug() << "QML loaded successfully!";
    return app.exec();
}
