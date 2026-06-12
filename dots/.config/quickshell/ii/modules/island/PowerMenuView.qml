pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    function handleAction(action) {
        // Collapse the island before executing
        GlobalStates.sessionOpen = false;

        if (action === "lock") {
            Quickshell.execDetached(["loginctl", "lock-session"]);
        } else if (action === "suspend") {
            Quickshell.execDetached(["systemctl", "suspend"]);
        } else if (action === "logout") {
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
        } else if (action === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (action === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        Repeater {
            model: ListModel {
                id: powerModel
                ListElement { name: "Lock"; icon: ""; action: "lock" }
                ListElement { name: "Suspend"; icon: ""; action: "suspend" }
                ListElement { name: "Log Out"; icon: ""; action: "logout" }
                ListElement { name: "Reboot"; icon: ""; action: "reboot" }
                ListElement { name: "Power Off"; icon: ""; action: "shutdown" }
            }

            delegate: Rectangle {
                id: buttonRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16

                required property string name
                required property string icon
                required property string action

                MouseArea {
                    id: clickArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.handleAction(action)
                }

                color: clickArea.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer1

                Behavior on color {
                    ColorAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: icon
                        Layout.alignment: Qt.AlignCenter
                        font.family: Appearance.fontFamily || "sans-serif"
                        font.pixelSize: 22
                        color: clickArea.containsMouse ? Appearance.colors.colLayer0 : Appearance.colors.colOnLayer0

                        Behavior on color {
                            ColorAnimation { duration: 120; easing.type: Easing.OutQuad }
                        }
                    }

                    Text {
                        text: name
                        Layout.alignment: Qt.AlignCenter
                        font.family: Appearance.fontFamily || "sans-serif"
                        font.pixelSize: 11
                        font.bold: true
                        color: clickArea.containsMouse ? Appearance.colors.colLayer0 : Appearance.colors.colOnLayer0

                        Behavior on color {
                            ColorAnimation { duration: 120; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
