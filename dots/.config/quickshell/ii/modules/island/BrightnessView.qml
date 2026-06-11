import QtQuick
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    
    property var screen: null

    
    Item {
        id: iconContainer
        width: 16
        height: 16
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: brightIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            visible: false
            source: "../../assets/icons/fluent/weather-sunny-filled.svg"
        }

        ColorOverlay {
            anchors.fill: brightIcon
            source: brightIcon
            color: Appearance.colors.colOnLayer0
        }
    }

    
    Text {
        id: percentText
        text: Math.round((Brightness.getMonitorForScreen(root.screen)?.brightness ?? 0.5) * 100) + "%"
        color: Appearance.colors.colOnLayer0
        font.family: Appearance.fontFamily || "sans-serif"
        font.pixelSize: 11
        font.bold: true
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        horizontalAlignment: Text.AlignRight
    }

    
    Rectangle {
        id: sliderTrack
        height: 6
        radius: 3
        color: Qt.rgba(1, 1, 1, 0.12)
        anchors.left: iconContainer.right
        anchors.leftMargin: 12
        anchors.right: percentText.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        
        Rectangle {
            height: parent.height
            radius: parent.radius
            color: Appearance.colors.colPrimary
            width: sliderTrack.width * (Brightness.getMonitorForScreen(root.screen)?.brightness ?? 0.5)
        }
    }
}
