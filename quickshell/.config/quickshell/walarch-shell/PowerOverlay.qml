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
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: "#1d2021"
                opacity: 0.85

                MouseArea {
                    anchors.fill: parent
                    onClicked: PowerMenuState.open = false
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacing * 2

                    MouseArea {
                        width: cardRow.implicitWidth
                        height: cardRow.implicitHeight
                        onClicked: {} // swallow

                        Row {
                            id: cardRow
                            spacing: Theme.spacing * 2

                            PowerCard {
                                label: "Lock"
                                onActivated: {
                                    lockProc.running = true
                                    PowerMenuState.open = false
                                }
                            }
                            PowerCard {
                                label: "Logout"
                                onActivated: {
                                    logoutProc.running = true
                                    PowerMenuState.open = false
                                }
                            }
                            PowerCard {
                                label: "Reboot"
                                danger: true
                                onActivated: {
                                    rebootProc.running = true
                                    PowerMenuState.open = false
                                }
                            }
                            PowerCard {
                                label: "Shutdown"
                                danger: true
                                onActivated: {
                                    shutdownProc.running = true
                                    PowerMenuState.open = false
                                }
                            }
                        }
                    }
                }
            }

            Process { id: lockProc; command: ["hyprlock"] }
            Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"] }
            Process { id: rebootProc; command: ["systemctl", "reboot"] }
            Process { id: shutdownProc; command: ["systemctl", "poweroff"] }
        }
    }
}
