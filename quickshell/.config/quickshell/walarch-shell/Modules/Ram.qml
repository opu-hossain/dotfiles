import QtQuick
import ".." // Theme, Poller

Rectangle {
    height: Theme.barHeight
    width: ramRow.implicitWidth + 20
    color: Theme.bgSoft

    property real usage: 0

    Row {
        id: ramRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "MEM"
            color: Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }

        Text {
            text: Math.round(usage) + "%"
            color: usage > 90 ? Theme.danger : usage > 50 ? Theme.warning : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            font.bold: true
        }
    }

    Poller {
        command: ["sh", "-c", "free | awk '/^Mem:/{printf \"%.1f\", $3*100/$2}'"]
        interval: 3000
        onResult: text => usage = parseFloat(text)
    }
}
