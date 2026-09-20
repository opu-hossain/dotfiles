import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

Pill {
    id: root

    property string title: Hyprland.activeToplevel?.title ?? ""
    property string display: title.length === 0
        ? "󰇄 Desktop"
        : (title.length > 40 ? title.substring(0, 40) + "…" : title)

    Text {
        text: root.display
        color: Qt.rgba(0.92, 0.86, 0.70, 0.8)   // fg @ 0.8
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
}
