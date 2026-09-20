import QtQuick
import Quickshell
import "." // Theme
import "Modules" as Modules

ShellRoot {
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

            // Left: workspaces + focused window title
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing * 2

                Modules.Workspaces {}
                Modules.WindowTitle {}
            }

            // Center: clock
            Modules.Clock {
                anchors.centerIn: parent
            }

            // Right: system modules
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

    PowerOverlay {}
    Launcher {}
    Notifications {}
}
