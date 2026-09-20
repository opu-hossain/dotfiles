import QtQuick
import Quickshell
import Quickshell.Io
import "." // Theme, PowerMenuState

Item {
    IpcHandler {
        target: "power"
        function toggle(): void {
            PowerMenuState.open = !PowerMenuState.open
        }
    }

    LazyLoader {
        active: PowerMenuState.open

        PanelWindow {
            id: win
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            focusable: true

            property int    selectedIndex: 0
            property string pendingAction: ""
            property string pendingLabel: ""
            property var    activeProcess: null

            readonly property var actions: [
                { key: "lock",     label: "Lock",     desc: "Lock the screen",         danger: false, hotkey: "l" },
                { key: "logout",   label: "Logout",   desc: "End the session",         danger: false, hotkey: "o" },
                { key: "suspend",  label: "Suspend",  desc: "Sleep, keep the session", danger: false, hotkey: "s" },
                { key: "reboot",   label: "Reboot",   desc: "Restart the system",      danger: true,  hotkey: "r" },
                { key: "shutdown", label: "Shutdown", desc: "Power off the system",    danger: true,  hotkey: "p" }
            ]

            function procFor(key) {
                switch (key) {
                case "lock":     return lockProc
                case "logout":   return logoutProc
                case "suspend":  return suspendProc
                case "reboot":   return rebootProc
                case "shutdown": return shutdownProc
                }
                return null
            }

            function runAction(action) {
                const proc = procFor(action.key)
                if (!proc) return
                if (action.danger) {
                    win.pendingAction = action.key
                    win.pendingLabel  = action.label
                    win.activeProcess = proc
                } else {
                    proc.running = true
                    PowerMenuState.open = false
                }
            }

            function confirmAction() {
                if (win.activeProcess) win.activeProcess.running = true
                PowerMenuState.open = false
            }

            function cancelAction() {
                win.pendingAction = ""
                win.pendingLabel  = ""
                win.activeProcess = null
            }

            function moveBy(delta) {
                const n = actions.length
                selectedIndex = ((selectedIndex + delta) % n + n) % n
            }

            onVisibleChanged: if (visible) {
                cancelAction()
                selectedIndex = 0
                keyCatcher.forceActiveFocus()
            }

            // ---------- Focus / key catcher ----------
            Item {
                id: keyCatcher
                anchors.fill: parent
                focus: true

                Keys.onPressed: e => {
                    const ctrl = (e.modifiers & Qt.ControlModifier) !== 0

                    // Esc: cancel pending, else close
                    if (e.key === Qt.Key_Escape || (ctrl && e.key === Qt.Key_BracketLeft)) {
                        if (win.pendingAction !== "") win.cancelAction()
                        else PowerMenuState.open = false
                        e.accepted = true
                        return
                    }

                    // Confirmation modal: only Enter and Esc handled
                    if (win.pendingAction !== "") {
                        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            win.confirmAction()
                            e.accepted = true
                        }
                        return
                    }

                    // Navigation
                    if (e.key === Qt.Key_Down || e.key === Qt.Key_J) {
                        win.moveBy(1); e.accepted = true; return
                    }
                    if (e.key === Qt.Key_Up || e.key === Qt.Key_K) {
                        win.moveBy(-1); e.accepted = true; return
                    }
                    if (e.key === Qt.Key_Home) { win.selectedIndex = 0; e.accepted = true; return }
                    if (e.key === Qt.Key_End)  { win.selectedIndex = win.actions.length - 1; e.accepted = true; return }

                    // Activate
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        win.runAction(win.actions[win.selectedIndex])
                        e.accepted = true
                        return
                    }

                    // Single-key hotkeys
                    if (e.text.length === 1 && !ctrl) {
                        const k = e.text.toLowerCase()
                        for (let i = 0; i < win.actions.length; i++) {
                            if (win.actions[i].hotkey === k) {
                                win.selectedIndex = i
                                win.runAction(win.actions[i])
                                e.accepted = true
                                return
                            }
                        }
                    }

                    if (e.key === Qt.Key_Q) {
                        PowerMenuState.open = false
                        e.accepted = true
                        return
                    }
                }

                // ---------- Backdrop ----------
                Rectangle {
                    anchors.fill: parent
                    color: "#0d0e0e"
                    opacity: 0.72

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (win.pendingAction !== "") win.cancelAction()
                            else PowerMenuState.open = false
                        }
                    }
                }

                // ---------- Main card ----------
                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: 480
                    height: mainColumn.implicitHeight
                    radius: Theme.radius + 6
                    color: Theme.bg
                    border.color: Theme.accent
                    border.width: 1

                    opacity: win.pendingAction === "" ? 1 : 0
                    scale:   win.pendingAction === "" ? 1 : 0.97

                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        enabled: win.pendingAction === ""
                        onClicked: {}
                    }

                    Column {
                        id: mainColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        // -------- Header --------
                        Item {
                            width: parent.width
                            height: 82

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 26
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: "Power"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 7
                                    font.bold: true
                                }
                                Text {
                                    text: "Choose what to do"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.fgMuted
                            opacity: 0.2
                        }

                        // -------- Action rows --------
                        Repeater {
                            model: win.actions

                            delegate: Rectangle {
                                id: row
                                required property int index
                                required property var modelData

                                readonly property bool  selected: index === win.selectedIndex
                                readonly property color accentColor:
                                    modelData.danger ? Theme.danger : Theme.accent

                                width: mainColumn.width
                                height: 66
                                color: selected ? Theme.bgSoft : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                // Left accent bar when selected
                                Rectangle {
                                    width: 3
                                    height: parent.height
                                    color: row.accentColor
                                    visible: row.selected

                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                // Label
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 26
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: row.selected && modelData.danger
                                           ? Theme.danger
                                           : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 3
                                    font.bold: row.selected
                                    width: 120

                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                // Description
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 26 + 120
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.desc
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }

                                // Hotkey badge
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 4
                                    color: row.selected ? row.accentColor : "transparent"
                                    border.color: row.selected ? row.accentColor : Theme.fgMuted
                                    border.width: 1
                                    opacity: row.selected ? 1.0 : 0.5

                                    Behavior on color   { ColorAnimation { duration: 100 } }
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.hotkey.toUpperCase()
                                        color: row.selected ? Theme.bg : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 1
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: win.pendingAction === ""      // <-- add this
                                    onEntered: win.selectedIndex = index
                                    onClicked: win.runAction(modelData)
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.fgMuted
                            opacity: 0.15
                        }

                        // -------- Footer --------
                        Item {
                            width: parent.width
                            height: 44

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 26
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 16

                                Text {
                                    text: "↑↓ jk"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                }
                                Text {
                                    text: "↵ select"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                }
                                Text {
                                    text: "esc close"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                }
                            }
                        }
                    }
                }

                // ---------- Confirmation modal ----------
                Rectangle {
                    id: confirmBox
                    anchors.centerIn: parent
                    width: 420
                    height: 240
                    radius: Theme.radius + 6
                    color: Theme.bg
                    border.color: Theme.danger
                    border.width: 1

                    opacity: win.pendingAction === "" ? 0 : 1
                    scale:   win.pendingAction === "" ? 0.96 : 1

                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        enabled: win.pendingAction !== ""
                        onClicked: {}
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 14

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.pendingLabel + "?"
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 8
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "This will terminate your session."
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Item { width: 1; height: 8 }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 14

                            Rectangle {
                                width: 132
                                height: 46
                                radius: Theme.radius
                                color: cancelMouse.containsMouse ? Theme.bgSoft : "transparent"
                                border.color: Theme.fgMuted
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 2
                                }

                                MouseArea {
                                    id: cancelMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.cancelAction()
                                }
                            }

                            Rectangle {
                                width: 132
                                height: 46
                                radius: Theme.radius
                                color: confirmMouse.containsMouse
                                       ? Theme.danger
                                       : Qt.darker(Theme.danger, 1.5)
                                border.color: Theme.danger
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Confirm"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 2
                                    font.bold: true
                                }

                                MouseArea {
                                    id: confirmMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.confirmAction()
                                }
                            }
                        }
                    }
                }
            }

            // ---------- Process workers ----------
            Process { id: lockProc;     command: ["hyprlock"] }
            Process { id: logoutProc;   command: ["hyprctl", "dispatch", "exit"] }
            Process {
                id: suspendProc
                // Lock first so wake lands on the lock screen, then suspend.
                command: ["sh", "-c", "hyprlock & sleep 0.3; systemctl suspend"]
            }
            Process { id: rebootProc;   command: ["systemctl", "reboot"] }
            Process { id: shutdownProc; command: ["systemctl", "poweroff"] }
        }
    }
}
