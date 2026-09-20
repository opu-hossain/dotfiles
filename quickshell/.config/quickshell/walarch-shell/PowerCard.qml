import QtQuick
import "." // Theme

Rectangle {
    id: card

    property string label: ""
    property bool danger: false
    signal activated()

    width: 150
    height: 150
    radius: Theme.radius + 6
    color: mouse.containsMouse ? Theme.bgSoft : Theme.bg
    border.color: danger ? Theme.danger : Theme.accent
    border.width: mouse.containsMouse ? 2 : 1
    scale: mouse.containsMouse ? 1.03 : 1.0

    Behavior on color        { ColorAnimation  { duration: 140 } }
    Behavior on border.width { NumberAnimation { duration: 140 } }
    Behavior on scale        { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Text {
        anchors.centerIn: parent
        text: card.label
        color: danger ? Theme.danger : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 5
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: card.activated()
    }
}
