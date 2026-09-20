import QtQuick
import Quickshell.Io
import "../" // Theme

Row {
    spacing: 4
    visible: count > 0 // hide entirely when everything's up to date

    property int count: 0

    Text {
        text: "⟳ " + count
        color: count > 0 ? Theme.accent : Theme.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Process {
        id: checkProc
        // checkupdates exits non-zero with no output when nothing's pending —
        // the `|| true` keeps that from being treated as a stream error
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l || true"]
        stdout: SplitParser {
            onRead: data => count = parseInt(data.trim()) || 0
        }
    }

    Timer {
        interval: 1800000 // 30 minutes — don't hammer the mirror
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
