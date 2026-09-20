import QtQuick
import ".." // Theme

Rectangle {
    id: clockBox
    height: Theme.barHeight
    width: clockText.implicitWidth + 20
    color: Theme.modeNormal

    property string timeStr: Qt.formatDateTime(new Date(), "hh:mm AP")

    Text {
        id: clockText
        anchors.centerIn: parent
        text: clockBox.timeStr
        color: Theme.bgHard
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockBox.timeStr = Qt.formatDateTime(new Date(), "hh:mm AP")
    }
}
