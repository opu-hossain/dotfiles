import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".." // Theme

Row {
    spacing: 0

    property int focusedId: Hyprland.focusedWorkspace?.id ?? -1

    property var displayList: {
        const _ = Hyprland.workspaces?.values.length + focusedId
        const wsList = Hyprland.workspaces?.values ?? []
        const activeIds = wsList.map(w => w.id).filter(id => id > 0)
        const maxId = Math.max(4, 0, ...activeIds)

        const out = []
        for (let i = 1; i <= maxId; i++) {
            out.push({
                id: i,
                focused: focusedId === i,
                exists: activeIds.indexOf(i) !== -1
            })
        }
        return out
    }

    // Mode block simulator at the far left
    Rectangle {
        height: Theme.barHeight
        width: modeText.implicitWidth + 32
        color: Theme.modeNormal

        Text {
            id: modeText
            anchors.centerIn: parent
            text: "archy"
            color: Theme.bgHard
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            font.bold: true
        }
    }

    // Powerline arrow from Mode to Workspaces
    Text {
        text: ""
        color: Theme.modeNormal
        font.family: Theme.fontFamily
        font.pixelSize: Theme.barHeight - 8
        anchors.verticalCenter: parent.verticalCenter
    }

    // Buffer Tabs
    Repeater {
        model: displayList

        delegate: Rectangle {
            required property var modelData

            height: Theme.barHeight
            width: wsText.implicitWidth + 16
            color: modelData.focused ? Theme.bgSoft : Theme.bg

            Text {
                id: wsText
                anchors.centerIn: parent
                text: modelData.id
                color: modelData.focused ? Theme.fg : (modelData.exists ? Theme.fgMuted : "#504945")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2
                font.bold: modelData.focused
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
