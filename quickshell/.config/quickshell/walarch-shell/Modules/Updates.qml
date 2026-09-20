import QtQuick
import Quickshell
import Quickshell.Io
import ".." // Theme

Rectangle {
    id: root

    height: Theme.barHeight
    width: count > 0 ? updatesRow.implicitWidth + 20 : 0
    visible: count > 0
    color: mouse.containsMouse ? Theme.bg : Theme.bgSoft

    property int count: 0

    Behavior on color { ColorAnimation { duration: 120 } }

    // Listens for external IPC calls to trigger an immediate check
    IpcHandler {
        target: "updates"
        function refresh(): void {
            checkProc.running = true
        }
    }

    Row {
        id: updatesRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "PKG"
            color: Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }

        Text {
            text: root.count
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            font.bold: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "(checkupdates 2>/dev/null; yay -Qua 2>/dev/null) | wc -l || true"]
        stdout: SplitParser {
            onRead: data => count = parseInt(data.trim()) || 0
        }
    }

    Timer {
        interval: 1800000 // 30 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
