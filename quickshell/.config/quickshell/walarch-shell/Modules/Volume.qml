import QtQuick
import Quickshell.Services.Pipewire
import ".." // Theme

Rectangle {
    id: root
    height: Theme.barHeight
    width: volRow.implicitWidth + 20
    color: Theme.bgSoft

    property var sink: Pipewire.defaultAudioSink

    PwObjectTracker { objects: [root.sink] }

    Row {
        id: volRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "VOL"
            color: root.sink?.audio.muted ? Theme.danger : Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }

        Text {
            text: root.sink?.audio 
                ? (root.sink.audio.muted ? "MUTE" : Math.round(root.sink.audio.volume * 100) + "%") 
                : "--"
            color: root.sink?.audio.muted ? Theme.danger : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (root.sink?.ready && root.sink?.audio)
                root.sink.audio.muted = !root.sink.audio.muted
        }
        onWheel: wheel => {
            if (!root.sink?.ready || !root.sink?.audio) return
            const step = 0.05
            const delta = wheel.angleDelta.y > 0 ? step : -step
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta))
        }
    }
}
