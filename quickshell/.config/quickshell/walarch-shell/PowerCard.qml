import QtQuick
import "." // Theme

Rectangle {
    id: card

    property string label: ""
    property bool danger: false
    signal activated()

    width: 100
    height: 110
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.bgSoft : Theme.bg
    border.color: danger ? Theme.danger : Theme.accent
    border.width: mouse.containsMouse ? 2 : 1

    Text {
        anchors.centerIn: parent
        text: card.label
        color: danger ? Theme.danger : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: card.activated()
    }
}
