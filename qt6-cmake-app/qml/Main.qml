import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: root
    width: 360
    height: 480
    visible: true
    title: qsTr("Qt6 CMake QML Example")

    MessageDialog {
        id: welcomeDialog
        title: qsTr("Hello")
        text: qsTr("Welcome to the Qt6 CMake example!")
        buttons: MessageDialog.Ok
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Label {
            text: qsTr("Qt Quick UI")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            width: root.width
        }

        Button {
            text: qsTr("Say Hello")
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: welcomeDialog.open()
        }
    }
}
