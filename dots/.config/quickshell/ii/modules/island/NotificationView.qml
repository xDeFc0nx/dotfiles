import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    property var notificationData: islandWindow.activeNotification

    // postNotification() flattens the notification into one `icon` string, so look the tracked
    // notification up to feed the shared icon widget the same fields every other notification
    // surface passes through.
    readonly property var trackedNotification: {
        const id = root.notificationData ? root.notificationData.id : undefined;
        if (id === undefined)
            return null;
        const index = Notifications.list.findIndex((notif) => notif.notificationId === id);
        return index >= 0 ? Notifications.list[index] : null;
    }
    readonly property string appName: root.notificationData ? String(root.notificationData.appName ?? "") : ""
    readonly property string summary: root.notificationData ? String(root.notificationData.title ?? "") : ""
    readonly property string body: root.notificationData ? String(root.notificationData.body ?? "") : ""
    readonly property string processedBody: NotificationUtils.processNotificationBody(root.body, root.appName || root.summary).replace(/\n/g, "<br/>")

    Rectangle {
        id: notificationBackground
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: ColorUtils.transparentize(Appearance.colors.colLayer3, clickArea.containsMouse ? 0.6 : 1)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (!root.notificationData || root.notificationData.id === undefined) return;

            if (mouse.button === Qt.LeftButton) {
                Notifications.attemptInvokeAction(root.notificationData.id, "default");
            } else if (mouse.button === Qt.RightButton) {
                Notifications.discardNotification(root.notificationData.id);
            }
            islandWindow.isExpanded = false;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 16

        NotificationAppIcon {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignVCenter
            appIcon: root.trackedNotification?.appIcon ?? ""
            image: root.trackedNotification?.image ?? ""
            summary: root.summary
            urgency: root.trackedNotification?.notification?.urgency ?? NotificationUrgency.Normal
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer3
                elide: Text.ElideRight
                text: root.summary.length > 0 ? root.summary : "New Notification"
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 1
                textFormat: Text.StyledText
                text: root.processedBody
            }
        }
    }
}
