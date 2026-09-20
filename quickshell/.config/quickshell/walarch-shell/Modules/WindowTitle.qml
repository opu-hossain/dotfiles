import QtQuick
import Quickshell.Hyprland
import ".." // Theme

Rectangle {
    id: root

    height: Theme.barHeight
    // Shrinks width to 0 when no window belongs to the current workspace
    width: display.length > 0 ? titleText.implicitWidth + 20 : 0
    visible: display.length > 0
    color: Theme.bgSoft

    // Fetch the active window and current workspace ID
    property var activeWin: Hyprland.activeToplevel
    property int currentWsId: Hyprland.focusedWorkspace?.id ?? -1

    // Verify the active window actually belongs to the focused workspace
    property bool isCurrentWorkspaceWindow: activeWin && activeWin.workspace && activeWin.workspace.id === currentWsId

    property string rawTitle: isCurrentWorkspaceWindow ? (activeWin.title ?? "") : ""
    property string display: rawTitle.length === 0 
        ? "" 
        : (rawTitle.length > 40 ? rawTitle.substring(0, 40) + "…" : rawTitle)

    Text {
        id: titleText
        anchors.centerIn: parent
        text: root.display
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 2
        font.bold: true
    }
}
