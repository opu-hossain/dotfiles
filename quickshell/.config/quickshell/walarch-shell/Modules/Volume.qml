import QtQuick
import Quickshell.Services.Pipewire
import ".." // Theme

Item {
    id: root

    property var sink: Pipewire.defaultAudioSink

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    PwObjectTracker {
        objects: [root.sink]
    }

    Row {
        id: content
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.sink?.audio.muted ? "MUTE" : "VOL"
            color: root.sink?.audio.muted ? Theme.accent : Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium

            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.sink?.audio ? Math.round(root.sink.audio.volume * 100) + "%" : "--"
            color: root.sink?.audio.muted ? Theme.accent : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
            width: 36
            horizontalAlignment: Text.AlignLeft

            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
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
