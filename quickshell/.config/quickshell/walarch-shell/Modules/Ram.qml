import QtQuick
import Quickshell.Io
import "../" // Theme

Row {
    spacing: 4

    property real usage: 0

    Text {
        text: "RAM"
        color: Theme.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
    Text {
        text: Math.round(usage) + "%"
        color: usage > 85 ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
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
