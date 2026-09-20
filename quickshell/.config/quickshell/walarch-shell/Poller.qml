import QtQuick
import Quickshell.Io

// Shared "run a shell command on a timer, hand back its stdout" component.
// Used by Modules/Cpu.qml, Ram.qml, Updates.qml, and Network.qml so the
// spawn/collect/reschedule plumbing exists in exactly one place; each
// module keeps only its own parsing logic in an onResult handler.
Item {
    id: root

    property var command: []
    property int interval: 2000
    property bool triggeredOnStart: true
    property bool active: true

    // Emitted with trimmed stdout every time `command` finishes running.
    signal result(string text)

    // Trigger a run right now, outside the normal interval — e.g. from an
    // IpcHandler that wants an immediate refresh.
    function refresh() {
        if (root.command.length > 0) proc.running = true
    }

    Process {
        id: proc
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: root.result(this.text.trim())
        }
    }

    Timer {
        interval: root.interval
        running: root.active
        repeat: true
        triggeredOnStart: root.triggeredOnStart
        // Guards the same way the old Network.qml did by hand: skip the run
        // if there's no command yet (e.g. iface not detected yet).
        onTriggered: if (root.command.length > 0) proc.running = true
    }
}
