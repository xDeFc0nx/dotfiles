import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import "controlcenter/AppColorHelper.js" as AppColorHelper

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    property var notificationData: islandWindow.activeNotification
    readonly property bool darkmode: Appearance.m3colors && Appearance.m3colors.darkmode
    readonly property string appName: notificationData ? notificationData.appName : ""
    readonly property color accentColor: appName.length > 0 ? AppColorHelper.accentStripeColor(appName, darkmode) : Appearance.colors.colPrimary
    readonly property color iconBgColor: appName.length > 0 ? AppColorHelper.iconBackgroundColor(appName, darkmode) : Qt.rgba(255, 255, 255, 0.1)
    readonly property color appNameTextColor: appName.length > 0 ? AppColorHelper.appNameColor(appName, darkmode) : Appearance.colors.colOnLayer0
    readonly property color subtleBgTint: appName.length > 0 ? Qt.rgba(AppColorHelper.colorForApp(appName), 0.08) : "transparent"

    
    Rectangle {
        id: hoverBackground
        anchors.fill: parent
        color: clickArea.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : subtleBgTint
        radius: 12

        Behavior on color {
            ColorAnimation { duration: 150 }
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
                
                console.log("[NotificationView] Left-click (Open). ID: " + root.notificationData.id);
                Notifications.attemptInvokeAction(root.notificationData.id, "default");
            } else if (mouse.button === Qt.RightButton) {
                
                console.log("[NotificationView] Right-click (Ignore). ID: " + root.notificationData.id);
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

        Rectangle {
            id: accentStripe
            width: 3
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            radius: 1.5
            color: accentColor
            visible: appName.length > 0
        }

        Item {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: iconBgColor

                Image {
                    id: appIcon
                    anchors.fill: parent
                    anchors.margins: 4
                    source: {
                        var iconStr = root.notificationData ? root.notificationData.icon : "";
                        if (!iconStr) return "image://icon/dialog-information";
                        if (iconStr.startsWith("/") || iconStr.startsWith("file://")) {
                            return iconStr;
                        }
                        return "image://icon/" + iconStr;
                    }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true 
                }

                ColorOverlay {
                    anchors.fill: appIcon
                    source: appIcon
                    color: Appearance.colors.colOnLayer0
                    visible: appIcon.source.toString().includes("-symbolic") || appIcon.source.toString().includes("status/")
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: root.notificationData ? root.notificationData.title : "New Notification"
                color: appNameTextColor
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.notificationData ? root.notificationData.body : ""
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
