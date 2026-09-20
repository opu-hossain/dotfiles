import QtQuick
import ".." // Theme, PowerMenuState

Rectangle {
    id: root

    height: Theme.barHeight
    width: powerIcon.implicitWidth + 24
    color: mouse.containsMouse || PowerMenuState.open ? Theme.accent : Theme.bgSoft

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: powerIcon
        anchors.centerIn: parent
        text: "⏻"
        color: mouse.containsMouse || PowerMenuState.open ? Theme.bgHard : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 4
        font.bold: true

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: PowerMenuState.open = !PowerMenuState.open
    }
}
