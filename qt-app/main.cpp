#include <QGuiApplication>
#include <QWindow>
#include <QScreen>
#include <QtPlugin>
#include <QDebug>

// Statically import the iOS platform plugin
Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)

int main(int argc, char *argv[])
{
    qDebug() << "Qt6 App Starting...";

    QGuiApplication app(argc, argv);
    qDebug() << "QGuiApplication created successfully!";

    // Create a simple window without QML
    QWindow window;
    window.setTitle("Qt6 Works!");
    window.resize(390, 844);
    window.show();

    qDebug() << "Window created and shown!";
    qDebug() << "Event loop starting...";

    return app.exec();
}
