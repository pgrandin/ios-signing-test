import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 390
    height: 844
    title: "Hello World"

    Rectangle {
        anchors.fill: parent
        color: "#f5f5f5"

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "Hello World from Qt6!"
                font.pixelSize: 32
                font.bold: true
                color: "#007AFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Built with GitHub Actions + CMake"
                font.pixelSize: 16
                color: "#666666"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
