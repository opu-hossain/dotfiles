import QtQuick
import Quickshell
import Quickshell.Io
import "." // Theme, LauncherState

Item {
    // IpcHandler must live outside the LazyLoader below — it needs to exist
    // even while the launcher is closed, since its whole job is opening it.
    // Wire this to Hyprland with:
    //   bind = $mod, D, exec, qs -c walarch-shell ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherState.open = !LauncherState.open
        }
    }

    LazyLoader {
        active: LauncherState.open

        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            focusable: true // required to receive keyboard input for search

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: "#1d2021"
                opacity: 0.85

                MouseArea {
                    anchors.fill: parent
                    onClicked: LauncherState.open = false
                }

                Rectangle {
                    id: box
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.25
                    width: 480
                    height: 400
                    radius: Theme.radius
                    color: Theme.bg
                    border.color: Theme.accent
                    border.width: 1

                    // Swallow clicks so they don't fall through to the
                    // backdrop and close the launcher
                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing * 2
                        spacing: Theme.spacing

                        TextInput {
                            id: search
                            width: parent.width
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 2
                            focus: true
                            clip: true

                            Text {
                                text: "Search apps…"
                                color: Theme.fgMuted
                                font: search.font
                                visible: search.text.length === 0
                            }

                            Keys.onEscapePressed: LauncherState.open = false
                            Keys.onReturnPressed: {
                                if (filtered.length > 0) launchApp(filtered[0].exec)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.fgMuted
                            opacity: 0.3
                        }

                        ListView {
                            width: parent.width
                            height: parent.height - search.height - Theme.spacing * 3
                            clip: true
                            model: filtered

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 32
                                color: hoverArea.containsMouse ? Theme.bgSoft : "transparent"
                                radius: Theme.radius

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacing
                                    text: modelData.name
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: launchApp(modelData.exec)
                                }
                            }
                        }
                    }
                }
            }

            // Full app list, populated once each time the launcher opens
            property var apps: []
            property var filtered: {
                const q = search.text.toLowerCase()
                return q.length === 0
                    ? apps
                    : apps.filter(a => a.name.toLowerCase().includes(q))
            }

            function launchApp(execString) {
                Quickshell.execDetached(["sh", "-c", execString])
                LauncherState.open = false
                search.text = ""
            }

            Process {
                id: appScan
                command: ["sh", "-c",
                    "for f in /usr/share/applications/*.desktop " +
                    "\"$HOME/.local/share/applications\"/*.desktop; do " +
                    "[ -f \"$f\" ] || continue; " +
                    "grep -q '^NoDisplay=true' \"$f\" && continue; " +
                    "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
                    "ex=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); " +
                    "[ -z \"$name\" ] && continue; " +
                    "[ -z \"$ex\" ] && continue; " +
                    "printf '%s\\037%s\\n' \"$name\" \"$ex\"; " +
                    "done"
                ]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const seen = new Set()
                        const list = []
                        for (const line of this.text.split("\n")) {
                            if (!line) continue
                            const [name, execRaw] = line.split("\u001f")
                            if (!name || !execRaw || seen.has(name)) continue
                            seen.add(name)
                            // Strip desktop-entry field codes (%f %F %u %U %i %c %k)
                            const exec = execRaw.replace(/%[a-zA-Z]/g, "").trim()
                            list.push({ name: name, exec: exec })
                        }
                        list.sort((a, b) => a.name.localeCompare(b.name))
                        apps = list
                    }
                }
            }

            onVisibleChanged: if (visible) {
                appScan.running = true
                search.forceActiveFocus()
            }
        }
    }
}
