import QtQuick
import ".." // Theme

Text {
    id: clock

    property string timeStr: Qt.formatDateTime(new Date(), "hh:mm AP")

    text: timeStr
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize + 1
    font.bold: true

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.timeStr = Qt.formatDateTime(new Date(), "hh:mm AP")
    }
}
