import QtQuick
import ".." // Theme, PowerMenuState

Item {
    implicitWidth: label.implicitWidth + 8
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: "⏻"
        color: PowerMenuState.open ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 2
    }

    MouseArea {
        anchors.fill: parent
        onClicked: PowerMenuState.open = !PowerMenuState.open
    }
}
