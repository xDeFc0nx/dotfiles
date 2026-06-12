import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    property var notificationData: islandWindow.activeNotification

    
    Rectangle {
        id: hoverBackground
        anchors.fill: parent
        color: clickArea.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(255, 255, 255, 0)
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
                color: Qt.rgba(255, 255, 255, 0.1)

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
                color: Appearance.colors.colOnLayer0
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
