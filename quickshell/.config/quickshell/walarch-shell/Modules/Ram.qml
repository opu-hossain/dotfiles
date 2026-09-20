import QtQuick
import Quickshell.Io
import ".." // Theme

Row {
    spacing: 4

    property real usage: 0

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "RAM"
        color: Theme.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(usage) + "%"
        color: usage > 90 ? Theme.danger
             : usage > 75 ? Theme.warning
             : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
        width: 36
        horizontalAlignment: Text.AlignLeft

        Behavior on color { ColorAnimation { duration: 250 } }
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
