import QtQuick
import Quickshell.Hyprland
import ".." // Theme

Rectangle {
    height: Theme.barHeight
    width: titleText.implicitWidth + 20
    color: Theme.bgSoft

    property string rawTitle: Hyprland.activeToplevel?.title ?? ""
    property string display: rawTitle.length === 0 
        ? "[No Name]" 
        : (rawTitle.length > 40 ? rawTitle.substring(0, 40) + "…" : rawTitle)

    Text {
        id: titleText
        anchors.centerIn: parent
        text: display
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
}
