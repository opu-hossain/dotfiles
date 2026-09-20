import QtQuick
import Quickshell.Services.Pipewire
import "../" // Theme

Item {
    id: root

    property var sink: Pipewire.defaultAudioSink

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    // Required so Quickshell actually keeps this node's properties live —
    // without this, sink.audio.volume wouldn't update or accept writes
    PwObjectTracker {
        objects: [root.sink]
    }

    Row {
        id: content
        spacing: 4

        Text {
            text: (root.sink?.audio.muted ? "MUTE" : "VOL")
            color: root.sink?.audio.muted ? Theme.accent : Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: root.sink?.audio ? Math.round(root.sink.audio.volume * 100) + "%" : "--"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    // Now a sibling of Row (not a child of it), so anchors.fill is fine
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.sink?.ready && root.sink?.audio)
                root.sink.audio.muted = !root.sink.audio.muted
        }
        // Scroll to change volume, 5% per notch — same feel as Waybar's
        // pulseaudio module scroll binding
        onWheel: wheel => {
            if (!root.sink?.ready || !root.sink?.audio) return
            const step = 0.05
            const delta = wheel.angleDelta.y > 0 ? step : -step
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta))
        }
    }
}
