import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "." // Theme

Item {
    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: true
        actionsSupported: false
        // Untracked notifications are discarded immediately — tracking is
        // what keeps one alive long enough for us to render it as a toast
        onNotification: notification => notification.tracked = true
    }

    PanelWindow {
        anchors {
            top: true
            right: true
        }
        margins.top: Theme.spacing * 2
        margins.right: Theme.spacing * 2
        color: "transparent"
        exclusiveZone: 0 // don't reserve bar-like space, just float above
        implicitWidth: 320
        implicitHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: Theme.spacing

            Repeater {
                model: server.trackedNotifications

                delegate: Rectangle {
                    id: toast
                    required property var modelData

                    width: column.width
                    height: content.implicitHeight + Theme.spacing * 2
                    radius: Theme.radius
                    color: Theme.bg
                    border.color: Theme.accent
                    border.width: 1

                    Column {
                        id: content
                        anchors.fill: parent
                        anchors.margins: Theme.spacing
                        spacing: 2

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: toast.modelData.appName +
                                  (toast.modelData.summary ? " — " + toast.modelData.summary : "")
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            visible: (toast.modelData.body || "").length > 0
                            text: toast.modelData.body || ""
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    // Click to dismiss early
                    MouseArea {
                        anchors.fill: parent
                        onClicked: toast.modelData.dismiss()
                    }

                    Timer {
                        interval: 5000
                        running: true
                        onTriggered: toast.modelData.expire()
                    }
                }
            }
        }
    }
}
