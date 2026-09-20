import QtQuick
import Quickshell.Hyprland
import ".." // Theme

Text {
    property string title: Hyprland.activeToplevel?.title ?? ""
    property string display: title.length === 0
        ? "Desktop"
        : (title.length > 40 ? title.substring(0, 40) + "…" : title)

    text: display
    color: Theme.fg                                 // was fgMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
}
