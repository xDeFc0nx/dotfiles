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

    // Automatically clear and focus the input field when the auth request starts
    Connections {
        target: PolkitService
        function onActiveChanged() {
            if (PolkitService.active) {
                passwordInput.text = "";
                passwordInput.focus = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 10

        // --- HEADER ---
        RowLayout {
            spacing: 8
            
            Text {
                text: "" // Nerd Font padlock icon
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 16
                color: Appearance.colors.colPrimary
            }

            Text {
                text: Translation.tr("Authentication Required")
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 16
                font.bold: true
            }
        }

        // --- DESCRIPTION ---
        Text {
            Layout.fillWidth: true
            text: PolkitService.cleanMessage
            color: Appearance.colors.colOnLayer0
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            opacity: 0.85
        }

        // --- ACTION ID ---
        Text {
            Layout.fillWidth: true
            text: PolkitService.flow ? PolkitService.flow.actionId : ""
            color: Appearance.colors.colOnSurfaceVariant || "#888888"
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: 10
            opacity: 0.5
        }

        // --- PASSWORD INPUT ---
        TextField {
            id: passwordInput
            Layout.fillWidth: true
            placeholderText: PolkitService.cleanPrompt
            echoMode: TextInput.Password
            enabled: PolkitService.interactionAvailable
            
            background: Rectangle {
                radius: 12
                color: Appearance.colors.colLayer1
                border.width: passwordInput.activeFocus ? 2 : 1
                border.color: passwordInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
            }
            
            color: Appearance.colors.colOnLayer0
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: 13

            onAccepted: {
                if (PolkitService.active && text.length > 0) {
                    PolkitService.submit(text);
                }
            }
        }

        // --- FOOTER BUTTONS ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Item { Layout.fillWidth: true } // spacer

            // Cancel Button
            Rectangle {
                width: 76
                height: 32
                radius: 16
                color: Appearance.colors.colLayer1

                Text {
                    anchors.centerIn: parent
                    text: Translation.tr("Cancel")
                    color: Appearance.colors.colOnLayer0
                    font.family: Appearance.fontFamily || "sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PolkitService.cancel()
                }
            }

            // Authenticate Button
            Rectangle {
                width: 104
                height: 32
                radius: 16
                color: Appearance.colors.colPrimary

                Text {
                    anchors.centerIn: parent
                    text: Translation.tr("Authenticate")
                    color: Appearance.colors.colLayer0
                    font.family: Appearance.fontFamily || "sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (passwordInput.text.length > 0) {
                            PolkitService.submit(passwordInput.text);
                        }
                    }
                }
            }
        }
    }
}

