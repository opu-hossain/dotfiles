import QtQuick
import Quickshell.Io
import ".." // Theme

Rectangle {
    height: Theme.barHeight
    width: netRow.implicitWidth + 20
    color: Theme.bgSoft

    property string iface: ""
    property real rxKBps: 0
    property real txKBps: 0
    property var prevRx: -1
    property var prevTx: -1

    function fmt(kbps) {
        return kbps >= 1024 ? (kbps / 1024).toFixed(1) + "M" : Math.round(kbps) + "K"
    }

    Row {
        id: netRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "NET"
            color: Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }

        Text {
            text: "d:" + fmt(rxKBps) + " u:" + fmt(txKBps)
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            font.bold: true
        }
    }

    Process {
        id: ifaceProc
        command: ["sh", "-c", "ip route | awk '/^default/ {print $5; exit}'"]
        running: true
        stdout: SplitParser {
            onRead: data => iface = data.trim()
        }
    }

    Process {
        id: statsProc
        command: iface === "" ? [] : [
            "sh", "-c",
            "cat /sys/class/net/" + iface + "/statistics/rx_bytes " +
            "/sys/class/net/" + iface + "/statistics/tx_bytes"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length < 2) return
                const rx = parseInt(lines[0])
                const tx = parseInt(lines[1])
                if (prevRx >= 0) {
                    rxKBps = (rx - prevRx) / 1024 / 2
                    txKBps = (tx - prevTx) / 1024 / 2
                }
                prevRx = rx
                prevTx = tx
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (iface !== "") statsProc.running = true
    }
}
