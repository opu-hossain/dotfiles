import QtQuick
import Quickshell.Io
import ".." // Theme

Row {
    spacing: 4
    visible: count > 0

    property int count: 0

    Text {
        text: "⟳ " + count
        color: Theme.accent                            // was accent (yellow) — now blue
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l || true"]
        stdout: SplitParser {
            onRead: data => count = parseInt(data.trim()) || 0
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
