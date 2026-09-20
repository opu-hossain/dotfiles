import QtQuick
import Quickshell.Io
import "../" // Theme

Row {
    spacing: 4

    property real usage: 0
    property var prevIdle: -1
    property var prevTotal: -1

    Text {
        text: "CPU"
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
        id: statProc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                // line looks like: cpu  user nice system idle iowait irq softirq ...
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
