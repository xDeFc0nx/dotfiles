import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import "controlcenter/AppColorHelper.js" as AppColorHelper

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    property var notificationData: islandWindow.activeNotification
    readonly property bool darkmode: Appearance.m3colors && Appearance.m3colors.darkmode
    readonly property string appName: notificationData ? notificationData.appName : ""
    readonly property color iconBgColor: appName.length > 0 ? AppColorHelper.iconBackgroundColor(appName, darkmode) : Qt.rgba(255, 255, 255, 0.1)
    readonly property color appNameTextColor: appName.length > 0 ? AppColorHelper.appNameColor(appName, darkmode) : Appearance.colors.colOnLayer0
    readonly property color subtleBgTint: appName.length > 0 ? ColorUtils.applyAlpha(AppColorHelper.colorForApp(appName), 0.08) : "transparent"

    readonly property string genericIconSource: "../../assets/icons/fluent/alert.svg"
    readonly property string notificationIcon: {
        const value = root.notificationData ? String(root.notificationData.icon ?? "") : "";
        if (value.startsWith("image://icon/"))
            return value.slice("image://icon/".length).split("?")[0];
        return value;
    }
    readonly property string iconSource: {
        const name = root.notificationIcon;
        if (name.startsWith("/") || name.startsWith("file://"))
            return name;
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(name))
            return name;
        const themeIcon = name ? Quickshell.iconPath(name, true) : "";
        if (themeIcon)
            return themeIcon;
        const guessedIcon = AppSearch.guessIcon(root.appName || "");
        const appIcon = (guessedIcon && guessedIcon !== "image-missing") ? Quickshell.iconPath(guessedIcon, true) : "";
        return appIcon || root.genericIconSource;
    }
    readonly property bool tintIcon: root.iconSource === root.genericIconSource
        || root.notificationIcon.includes("-symbolic") || root.notificationIcon.includes("status/")

    
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
                    source: root.iconSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true 
                }

                ColorOverlay {
                    anchors.fill: appIcon
                    source: appIcon
                    color: Appearance.colors.colOnLayer0
                    visible: root.tintIcon
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
