import QtQuick
import Quickshell.Io
import ".." // Theme, Poller

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

    // One-shot bootstrap: find the default-route interface. This isn't a
    // periodic sample like the stats below, so it stays a plain Process
    // rather than going through Poller.
    Process {
        id: ifaceProc
        command: ["sh", "-c", "ip route | awk '/^default/ {print $5; exit}'"]
        running: true
        stdout: SplitParser {
            onRead: data => iface = data.trim()
        }
    }

    Poller {
        interval: 2000
        // Empty command until iface is known — Poller's own guard skips
        // running while this is [].
        command: iface === "" ? [] : [
            "sh", "-c",
            "cat /sys/class/net/" + iface + "/statistics/rx_bytes " +
            "/sys/class/net/" + iface + "/statistics/tx_bytes"
        ]
        onResult: text => {
            const lines = text.split("\n")
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
