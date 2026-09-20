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
            color: Theme.bgHard

            // Left Section (Mode + Workspaces + Window Title)
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Modules.Workspaces {}
                Modules.WindowTitle {}
            }

            // Right Section (System Metrics + Network + Time at Far Right)
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Modules.Cpu {}
                Modules.Ram {}
                Modules.Updates {}
                Modules.Network {}
                Modules.Volume {}
                Modules.Power {}
                Modules.Clock {}
            }
        }
    }

    PowerOverlay {}
    Launcher {}
    Notifications {}
}
