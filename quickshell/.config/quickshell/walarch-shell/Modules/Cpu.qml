import QtQuick
import Quickshell.Io
import ".." // Theme

Row {
    spacing: 4

    property real usage: 0
    property var prevIdle: -1
    property var prevTotal: -1

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "CPU"
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
        font.pixelSize: Theme.fontSize + 1     // matches clock
        font.bold: true                         // matches clock
        width: 36
        horizontalAlignment: Text.AlignLeft

        Behavior on color { ColorAnimation { duration: 250 } }
    }

    Process {
        id: statProc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/).slice(1).map(Number)
                const idle = parts[3]
                const total = parts.reduce((a, b) => a + b, 0)
                if (prevTotal >= 0) {
                    const totalDelta = total - prevTotal
                    const idleDelta = idle - prevIdle
                    usage = totalDelta > 0 ? (100 * (totalDelta - idleDelta)) / totalDelta : 0
                }
                prevIdle = idle
                prevTotal = total
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }
}
