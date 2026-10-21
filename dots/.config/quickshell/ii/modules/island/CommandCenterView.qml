import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.island.controlcenter
import qs.services
import qs.modules.waffle.actionCenter.wifi
import qs.modules.waffle.actionCenter.volumeControl

Item {
    id: root
    implicitWidth: 420
    implicitHeight: 600

    property var islandWindow: null

    RowLayout {
        id: header
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 16
            leftMargin: 24
            rightMargin: 24
        }
        height: 40
        spacing: 12

        Rectangle {
            id: backButton
            width: 40
            height: 40
            radius: 20
            color: Appearance.colors.colLayer1

            Text {
                anchors.centerIn: parent
                text: "←"
                color: Appearance.colors.colOnLayer0
                font.pixelSize: 20
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (stack.depth > 1) {
                        stack.pop()
                    } else if (root.islandWindow) {
                        root.islandWindow.controlCenterOpen = false
                    }
                }
            }
        }

        Text {
            text: stack.depth > 1 ? stack.currentItem.title : "Control Center"
            color: Appearance.colors.colOnLayer0
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: 22
            font.bold: true
        }
    }

    StackView {
        id: stack
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 12
            leftMargin: 24
            rightMargin: 24
            bottomMargin: 16
        }

        initialItem: mainView
    }

    Component {
        id: wifiView
        WifiControl {
            readonly property string title: "Wi-Fi"
            width: stack.width
            implicitHeight: 450
            height: implicitHeight
        }
    }

    Component {
        id: audioView
        VolumeControl {
            readonly property string title: "Audio"
            width: stack.width
            implicitHeight: 400
            height: implicitHeight
        }
    }

    Component {
        id: mainView
        ScrollView {
            id: mainScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical: ScrollBar {
                width: 6
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    radius: 3
                    color: Appearance.colors.colOutlineVariant
                    opacity: 0.5
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            ColumnLayout {
                id: mainColumn
                width: mainScroll.width
                spacing: 12
                readonly property string title: "Control Center"

                ToggleGrid {
                    stackViewRef: stack
                    wifiViewRef: wifiView
                    audioViewRef: audioView
                    Layout.fillWidth: true
                }

                SliderSection {
                    islandWindow: root.islandWindow
                    Layout.fillWidth: true
                }

                MediaCard {
                    Layout.fillWidth: true
                }

                NotificationHistory {
                    onOpenSidebarRequested: GlobalStates.sidebarRightOpen = true
                    Layout.fillWidth: true
                }
            }
        }
    }
}