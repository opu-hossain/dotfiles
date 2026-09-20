import QtQuick
import Quickshell
import "." // makes Theme (registered via qmldir) available as `Theme`
import "Modules" as Modules

// Root of the shell. Keep this file thin: it only wires up top-level
// surfaces (bar, launcher, notification popup, power menu...) so each
// one can be built/tested/swapped independently.
ShellRoot {
    // Bar: one per monitor, anchored to the top edge.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: Theme.bg

            Rectangle {
                anchors.fill: parent
                color: Theme.bg

                // Right-side module row — CPU, RAM for now; update checker,
                // network, volume, power join here once these are confirmed.
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing * 2

                    Modules.Cpu {}
                    Modules.Ram {}
                    Modules.Updates {}
                    Modules.Network {}
                    Modules.Volume {}
                    Modules.Power {}
                }
            }
        }
    }

    // One overlay for the whole shell (not per-monitor like the bar) —
    // created only while PowerMenuState.open is true
    PowerOverlay {}

    // App launcher — IpcHandler stays alive even when closed; toggle via:
    //   qs -c walarch-shell ipc call launcher toggle
    Launcher {}

    // Notification popups — claims the org.freedesktop.Notifications
    // D-Bus name, so SwayNC must be stopped for this to work cleanly
    Notifications {}
}
