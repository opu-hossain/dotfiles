import QtQuick
import Quickshell.Io
import ".." // Theme

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

    Process {
        id: freeProc
        command: ["sh", "-c", "free | awk '/^Mem:/{printf \"%.1f\", $3*100/$2}'"]
        stdout: SplitParser {
            onRead: data => usage = parseFloat(data.trim())
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: freeProc.running = true
    }
}
