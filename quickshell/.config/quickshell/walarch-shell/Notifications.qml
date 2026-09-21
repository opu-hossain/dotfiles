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
        // Untracked notifications are discarded immediately — tracking is
        // what keeps one alive long enough for us to render it as a toast
        onNotification: notification => notification.tracked = true
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

                    // Apps can request their own timeout (seconds); a negative
                    // value means "no preference", so fall back to an
                    // urgency-based default. Critical notifications never
                    // auto-expire — they wait for an explicit dismiss.
                    readonly property real autoExpireSeconds:
                        toast.modelData.expireTimeout >= 0 ? toast.modelData.expireTimeout :
                        urgency === NotificationUrgency.Critical ? -1 :
                        urgency === NotificationUrgency.Low ? 3 : 5

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

                    Timer {
                        running: toast.autoExpireSeconds >= 0
                        interval: toast.autoExpireSeconds * 1000
                        onTriggered: toast.modelData.expire()
                    }
                }
            }
        }
    }
}
