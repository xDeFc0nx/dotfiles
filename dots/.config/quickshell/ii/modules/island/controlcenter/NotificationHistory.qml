import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 10

    signal openSidebarRequested

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            id: notifTitle
            text: "Notifications"
            color: Appearance.colors.colOnLayer0
            font.family: Appearance.font.family.main
            font.pixelSize: Appearance.font.pixelSize.small
            font.bold: true
            font.variableAxes: Appearance.font.variableAxes.main
        }

        Rectangle {
            id: unreadBadge
            visible: Notifications.unread > 0
            height: 18
            radius: 9
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                text: Notifications.unread > 99 ? "99+" : Notifications.unread
                color: Appearance.colors.colOnPrimary
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.bold: true
                font.variableAxes: Appearance.font.variableAxes.main
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item { Layout.fillWidth: true }

        RippleButton {
            id: clearAllButton
            buttonText: "Clear all"
            buttonRadius: Appearance.rounding.small
            buttonRadiusPressed: Appearance.rounding.small
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.main
            font.variableAxes: Appearance.font.variableAxes.main
            releaseAction: () => Notifications.discardAllNotifications()
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ColumnLayout {
        id: notifList
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            id: notifRepeater
            model: Notifications.list

            delegate: NotificationHistoryItem {
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillWidth: true
            visible: notifRepeater.count === 0
            implicitHeight: 80

            Column {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    text: "notifications_active"
                    color: Appearance.colors.colOutline
                    font.pixelSize: 28
                }

                StyledText {
                    text: qsTr("No notifications")
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    font.variableAxes: Appearance.font.variableAxes.main
                }
            }
        }
    }
}