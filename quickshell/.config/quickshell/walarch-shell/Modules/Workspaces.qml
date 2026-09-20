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

        // Build set of workspace IDs to display:
        // Always include 1..5, plus any active/focused workspace > 5
        const idsToDisplay = new Set([1, 2, 3, 4, 5])
        for (const id of activeIds) {
            if (id > 5) idsToDisplay.add(id)
        }
        if (focusedId > 5) idsToDisplay.add(focusedId)

        // Sort the workspace IDs numerically
        const sortedIds = Array.from(idsToDisplay).sort((a, b) => a - b)

        const out = []
        for (const id of sortedIds) {
            out.push({
                id: id,
                focused: focusedId === id,
                exists: activeIds.indexOf(id) !== -1
            })
        }
        return out
    }

    // Leftmost Mode Block
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
            color: modelData.focused ? Theme.bgSoft : "transparent"

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
