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

    // Load inline QML
    engine.loadData(R"QML(
import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 390
    height: 844
    color: "#4CAF50"

    Rectangle {
        anchors.centerIn: parent
        width: 300
        height: 200
        color: "white"
        radius: 20

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "✅ Qt6 Works!"
                font.pixelSize: 36
                font.bold: true
                color: "#4CAF50"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Hello from iOS"
                font.pixelSize: 24
                color: "#666"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
)QML");

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "ERROR: Failed to load QML";
        return -1;
    }

    qDebug() << "QML loaded successfully!";
    return app.exec();
}
