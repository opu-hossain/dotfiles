import QtQuick
import Quickshell
import Quickshell.Io
import "." // Theme, LauncherState

Item {
    id: root

    // Cached scan + persisted launch counts, both live outside the LazyLoader
    // so they're ready the instant the launcher opens.
    property var   apps: []
    property bool  scanning: false
    property var   usage: ({})

    readonly property string stateDir:  "$HOME/.local/state/walarch-shell"
    readonly property string usageFile: "$HOME/.local/state/walarch-shell/launcher-usage.json"

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    function recordLaunch(name) {
        const next = Object.assign({}, root.usage)
        next[name] = (next[name] || 0) + 1
        root.usage = next

        const json = JSON.stringify(next)
        saveUsageProc.command = ["sh", "-c",
            "mkdir -p \"" + root.stateDir + "\" && printf %s " +
            shellQuote(json) + " > \"" + root.usageFile + "\""
        ]
        saveUsageProc.running = true
    }

    // Usage desc → alphabetical tiebreak. Recomputes whenever `apps` or
    // `usage` changes, since both are read here.
    property var sortedApps: {
        const u = root.usage
        const list = root.apps.slice()
        list.sort((a, b) => {
            const ca = u[a.name] || 0
            const cb = u[b.name] || 0
            if (ca !== cb) return cb - ca
            return a.name.localeCompare(b.name)
        })
        return list
    }

    // ---------- Load persisted usage at startup ----------
    Process {
        id: loadUsage
        command: ["sh", "-c", "cat \"" + root.usageFile + "\" 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text.trim() || "{}")
                    if (parsed && typeof parsed === "object") root.usage = parsed
                } catch (e) {
                    root.usage = ({})
                }
            }
        }
    }

    // ---------- Persist usage ----------
    Process { id: saveUsageProc }

    // ---------- Background app scanner ----------
    Process {
        id: appScan
        command: ["sh", "-c",
            "for f in /usr/share/applications/*.desktop " +
            "\"$HOME/.local/share/applications\"/*.desktop " +
            "/var/lib/flatpak/exports/share/applications/*.desktop " +
            "\"$HOME/.local/share/flatpak/exports/share/applications\"/*.desktop; do " +
            "[ -f \"$f\" ] || continue; " +
            "grep -q '^NoDisplay=true' \"$f\" && continue; " +
            "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "ex=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); " +
            "[ -z \"$name\" ] && continue; " +
            "[ -z \"$ex\" ] && continue; " +
            "printf '%s\\037%s\\n' \"$name\" \"$ex\"; " +
            "done"
        ]
        onRunningChanged: root.scanning = running
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = new Set()
                const list = []
                for (const line of this.text.split("\n")) {
                    if (!line) continue
                    const [name, execRaw] = line.split("\u001f")
                    if (!name || !execRaw || seen.has(name)) continue
                    seen.add(name)
                    const exec = execRaw.replace(/%[a-zA-Z]/g, "").trim()
                    list.push({
                        name: name,
                        exec: exec,
                        nameLower: name.toLowerCase(),
                        nameEscaped: root.escapeHtml(name)
                    })
                }
                root.apps = list
            }
        }
    }

    Component.onCompleted: appScan.running = true

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherState.open = !LauncherState.open
        }
    }

    LazyLoader {
        active: LauncherState.open

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

            property int   selectedIndex: 0
            property bool  insertMode: true
            property string vimPending: ""

            readonly property int rowHeight: 44
            readonly property int maxVisibleRows: 8

            property var filtered: {
                const q = search.text.toLowerCase()
                if (q.length === 0) return root.sortedApps
                return root.sortedApps.filter(a => a.nameLower.includes(q))
            }

            property int listHeight: {
                const n = filtered.length
                if (n === 0) return 120
                return Math.min(n * rowHeight, maxVisibleRows * rowHeight)
            }

            property int boxHeight: 52 + 1 + listHeight + 1 + 32

            onFilteredChanged: selectedIndex = 0

            function launchApp(app) {
                root.recordLaunch(app.name)
                Quickshell.execDetached(["sh", "-c", app.exec])
                LauncherState.open = false
                search.text = ""
                selectedIndex = 0
            }

            function moveBy(delta) {
                if (filtered.length === 0) return
                const n = filtered.length
                selectedIndex = ((selectedIndex + delta) % n + n) % n
                list.positionViewAtIndex(selectedIndex, ListView.Contain)
            }

            function moveTo(idx) {
                if (filtered.length === 0) return
                selectedIndex = Math.max(0, Math.min(idx, filtered.length - 1))
                list.positionViewAtIndex(selectedIndex, ListView.Contain)
            }

            function highlight(app, query) {
                if (query.length === 0) return app.nameEscaped
                const idx = app.nameLower.indexOf(query)
                if (idx < 0) return app.nameEscaped
                const pre  = root.escapeHtml(app.name.substring(0, idx))
                const hit  = root.escapeHtml(app.name.substring(idx, idx + query.length))
                const post = root.escapeHtml(app.name.substring(idx + query.length))
                return pre +
                       "<span style=\"color:" + Theme.accent +
                       ";font-weight:bold\">" + hit + "</span>" + post
            }

            Timer {
                id: vimTimer
                interval: 700
                onTriggered: win.vimPending = ""
            }

            // ---------- Backdrop ----------
            Rectangle {
                anchors.fill: parent
                color: "#0d0e0e"
                opacity: 0.72

                MouseArea {
                    anchors.fill: parent
                    onClicked: LauncherState.open = false
                }
            }

            // ---------- Launcher box ----------
            Rectangle {
                id: box
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(48, parent.height * 0.22)
                width: 620
                height: win.boxHeight
                radius: Theme.radius + 4
                color: Theme.bg
                border.color: Theme.accent
                border.width: 1

                opacity: 0
                scale: 0.97
                Component.onCompleted: { opacity = 1; scale = 1 }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on height  { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent; onClicked: {} }

                Column {
                    anchors.fill: parent
                    spacing: 0

                    // -------- Search input --------
                    Item {
                        width: parent.width
                        height: 52

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 4
                            focus: true
                            clip: true
                            selectByMouse: true

                            cursorDelegate: Rectangle {
                                width: win.insertMode
                                       ? 2
                                       : Math.round(search.font.pixelSize * 0.58)
                                height: Math.round(search.font.pixelSize * 1.15)
                                color: Theme.accent
                                radius: win.insertMode ? 0 : 2
                                opacity: win.insertMode ? 1.0 : 0.45

                                Behavior on width   { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                Behavior on radius  { NumberAnimation { duration: 90 } }
                                Behavior on opacity { NumberAnimation { duration: 90 } }
                            }

                            Text {
                                text: win.insertMode ? "Search applications…" : ""
                                color: Theme.fgMuted
                                font: search.font
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text.length === 0 && win.insertMode
                            }

                            Keys.onPressed: e => {
                                const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
                                const shift = (e.modifiers & Qt.ShiftModifier)   !== 0
                                const alt  = (e.modifiers & Qt.AltModifier)      !== 0
                                const meta = (e.modifiers & Qt.MetaModifier)     !== 0

                                // ===== Esc / Ctrl+[ =====
                                if (e.key === Qt.Key_Escape ||
                                    (ctrl && e.key === Qt.Key_BracketLeft)) {
                                    if (win.vimPending !== "") {
                                        win.vimPending = ""
                                    } else if (win.insertMode) {
                                        win.insertMode = false
                                        search.cursorPosition = Math.max(0, search.text.length - 1)
                                    } else {
                                        LauncherState.open = false
                                    }
                                    e.accepted = true
                                    return
                                }

                                // ===== Enter =====
                                if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    if (filtered.length > 0 && win.selectedIndex < filtered.length)
                                        launchApp(filtered[win.selectedIndex])
                                    e.accepted = true
                                    return
                                }

                                // ===== Universal navigation (both modes) =====
                                if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) {
                                    win.moveBy(1);  e.accepted = true; return
                                }
                                if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) {
                                    win.moveBy(-1); e.accepted = true; return
                                }
                                if (e.key === Qt.Key_PageDown || (ctrl && e.key === Qt.Key_D)) {
                                    win.moveBy(5);  e.accepted = true; return
                                }
                                if (e.key === Qt.Key_PageUp || (ctrl && e.key === Qt.Key_U)) {
                                    win.moveBy(-5); e.accepted = true; return
                                }
                                if (e.key === Qt.Key_Home) {
                                    win.moveTo(0);                   e.accepted = true; return
                                }
                                if (e.key === Qt.Key_End) {
                                    win.moveTo(filtered.length - 1); e.accepted = true; return
                                }

                                // ===== INSERT: everything else goes to the input =====
                                if (win.insertMode) return

                                // ===== NORMAL mode =====

                                if (win.vimPending === "d") {
                                    win.vimPending = ""
                                    if (e.key === Qt.Key_D) {
                                        search.text = ""
                                        win.moveTo(0)
                                        e.accepted = true
                                        return
                                    }
                                }

                                if (e.key === Qt.Key_J) { win.moveBy(1);  e.accepted = true; return }
                                if (e.key === Qt.Key_K) { win.moveBy(-1); e.accepted = true; return }

                                if (e.key === Qt.Key_H) {
                                    search.cursorPosition = Math.max(0, search.cursorPosition - 1)
                                    e.accepted = true
                                    return
                                }
                                if (e.key === Qt.Key_L) {
                                    search.cursorPosition = Math.min(search.text.length, search.cursorPosition + 1)
                                    e.accepted = true
                                    return
                                }
                                if (e.key === Qt.Key_0) {
                                    search.cursorPosition = 0
                                    e.accepted = true
                                    return
                                }
                                if (e.key === Qt.Key_Dollar) {
                                    search.cursorPosition = search.text.length
                                    e.accepted = true
                                    return
                                }

                                if (e.key === Qt.Key_D && shift) {
                                    search.text = ""
                                    win.moveTo(0)
                                    e.accepted = true
                                    return
                                }
                                if (e.key === Qt.Key_D) {
                                    win.vimPending = "d"
                                    vimTimer.restart()
                                    e.accepted = true
                                    return
                                }

                                if (e.key === Qt.Key_I) {
                                    win.insertMode = true
                                    search.cursorPosition = 0
                                    e.accepted = true
                                    return
                                }
                                if (e.key === Qt.Key_A || e.key === Qt.Key_Slash) {
                                    win.insertMode = true
                                    search.cursorPosition = search.text.length
                                    e.accepted = true
                                    return
                                }

                                if (e.key === Qt.Key_Q) {
                                    LauncherState.open = false
                                    e.accepted = true
                                    return
                                }

                                if (e.text.length > 0 && !alt && !meta) {
                                    win.insertMode = true
                                    return
                                }

                                e.accepted = true
                            }
                        }
                    }

                    // -------- Separator --------
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.fgMuted
                        opacity: 0.25
                    }

                    // -------- Results list --------
                    ListView {
                        id: list
                        width: parent.width
                        height: win.listHeight
                        clip: true
                        model: filtered
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height
                        cacheBuffer: win.rowHeight * 3

                        delegate: Rectangle {
                            id: row
                            required property int index
                            required property var modelData

                            width: ListView.view.width
                            height: win.rowHeight
                            color: index === win.selectedIndex ? Theme.bgSoft : "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Rectangle {
                                width: 3
                                height: parent.height
                                color: Theme.accent
                                visible: index === win.selectedIndex
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.right: parent.right
                                anchors.rightMargin: 20
                                textFormat: search.text.length > 0 ? Text.RichText : Text.PlainText
                                elide: Text.ElideRight
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 2
                                text: win.highlight(modelData, search.text)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: win.selectedIndex = index
                                onClicked: launchApp(modelData)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: filtered.length === 0
                            text: root.apps.length === 0
                                  ? (root.scanning ? "Scanning…" : "Loading…")
                                  : "No matches"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 1
                        }
                    }

                    // -------- Footer separator --------
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.fgMuted
                        opacity: 0.15
                    }

                    // -------- Footer --------
                    Item {
                        width: parent.width
                        height: 32

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Text {
                                text: "j/k ↑↓"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                            }
                            Text {
                                text: "↵ open"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                            }
                            Text {
                                text: "esc back"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                text: filtered.length + (filtered.length === 1 ? " app" : " apps")
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                            }
                            Text {
                                text: win.insertMode ? "INSERT" : "NORMAL"
                                color: win.insertMode ? Theme.fgMuted : Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.bold: !win.insertMode

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }
                    }
                }
            }

            onVisibleChanged: if (visible) {
                search.text = ""
                selectedIndex = 0
                insertMode = true
                vimPending = ""
                search.forceActiveFocus()
            }
        }
    }
}
