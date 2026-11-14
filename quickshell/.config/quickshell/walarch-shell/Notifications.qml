import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "." // Theme

Item {
    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: true
        actionsSupported: true

        readonly property int maxVisible: 4

        onNotification: notification => {
            notification.tracked = true

            // Cap the stack: dismiss the oldest ones beyond maxVisible
            const list = server.trackedNotifications.values
            const extra = list.length - server.maxVisible
            for (let i = 0; i < extra; i++)
                list[i].dismiss()
        }
    }

    PanelWindow {
        anchors {
            top: true
            right: true
        }
        // NOTE: deliberately literal pixel values, not Theme.spacing — that
        // token is 0 on purpose (it's what keeps the bar flush), which is
        // exactly wrong for a floating toast's padding/edge distance.
        margins.top: 14
        margins.right: 14
        color: "transparent"
        visible: server.trackedNotifications.values.length > 0
        exclusiveZone: 0 // don't reserve bar-like space, just float above
        implicitWidth: 380
        implicitHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: 10

            Repeater {
                model: server.trackedNotifications

                delegate: Rectangle {
                    id: toast
                    required property var modelData

                    readonly property int urgency: toast.modelData.urgency
                    readonly property color accentColor:
                        urgency === NotificationUrgency.Critical ? Theme.danger :
                        urgency === NotificationUrgency.Low ? Theme.fgMuted :
                        Theme.accent

                    // <= 0 means "app has no preference" (0 and -1 are both used in the wild),
                    // so fall back to urgency defaults. Nothing sticks forever: even critical
                    // toasts time out (click still dismisses early). Long app timeouts are capped.
                    readonly property real autoExpireSeconds: {
                        const t = toast.modelData.expireTimeout
                        if (urgency === NotificationUrgency.Critical) return 10
                        if (t > 0) return Math.min(t, 5)
                        return urgency === NotificationUrgency.Low ? 3 : 5
                    }

                    property bool hovered: hoverTracker.hovered

                    width: column.width
                    height: content.implicitHeight + 28
                    radius: Theme.radius // sharp — matches the accent stripe below
                    color: Theme.bgHard
                    border.color: toast.accentColor
                    border.width: urgency === NotificationUrgency.Critical ? 2 : 1

                    // Left accent stripe — same "selected row" language as
                    // Workspaces/Launcher/PowerOverlay elsewhere in the shell.
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: 4
                        color: toast.accentColor
                    }

                    Column {
                        id: content
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 18
                            rightMargin: 14
                            topMargin: 14
                        }
                        spacing: 8

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: toast.modelData.appName +
                                  (toast.modelData.summary ? " — " + toast.modelData.summary : "")
                            color: toast.accentColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 3
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            visible: (toast.modelData.body || "").length > 0
                            text: toast.modelData.body || ""
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 1
                        }

                        // ---- Image / thumbnail (e.g. a hyprshot preview) ----
                        Image {
                            width: parent.width
                            height: 140
                            visible: (toast.modelData.image || "").length > 0
                            source: toast.modelData.image || ""
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                        }

                        // ---- Action buttons ----
                        Row {
                            visible: toast.modelData.actions.length > 0
                            spacing: 8

                            Repeater {
                                model: toast.modelData.actions

                                delegate: Rectangle {
                                    id: actionBtn
                                    required property var modelData

                                    width: actionText.implicitWidth + 18
                                    height: actionText.implicitHeight + 10
                                    color: actionMouse.containsMouse ? toast.accentColor : "transparent"
                                    border.color: toast.accentColor
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: actionBtn.modelData.text
                                        color: actionMouse.containsMouse ? Theme.bgHard : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize

                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: actionBtn.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }

                    // Click anywhere else on the toast to dismiss early. z: -1
                    // keeps this strictly behind `content`, so the action
                    // buttons above always win the click over this
                    // background catch-all.
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: toast.modelData.dismiss()
                    }

                    HoverHandler { id: hoverTracker }

                    Timer {
                        running: toast.autoExpireSeconds > 0 && !toast.hovered
                        interval: Math.max(1, toast.autoExpireSeconds * 1000)
                        repeat: false
                        onTriggered: toast.modelData.dismiss()
                    }
                }
            }
        }
    }
}
