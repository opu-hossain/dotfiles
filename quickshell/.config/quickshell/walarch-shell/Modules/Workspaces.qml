import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".." // Theme

Row {
    spacing: 8

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

    Repeater {
        model: displayList

        delegate: Text {
            required property var modelData

            text: modelData.id
            color: modelData.focused ? Theme.accent
                 : modelData.exists  ? Theme.fg
                 :                     Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: modelData.focused

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
