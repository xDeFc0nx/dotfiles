import QtQuick
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    
    Item {
        id: iconContainer
        width: 16
        height: 16
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: volIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            visible: false
            source: {
                if (!Audio.sink?.audio) return "../../assets/icons/fluent/speaker-mute-filled.svg";
                if (Audio.sink.audio.muted) return "../../assets/icons/fluent/speaker-mute-filled.svg";
                
                var vol = Audio.sink.audio.volume;
                if (vol <= 0) return "../../assets/icons/fluent/speaker-off.svg";
                if (vol < 0.33) return "../../assets/icons/fluent/speaker-0.svg";
                if (vol < 0.66) return "../../assets/icons/fluent/speaker-1.svg";
                return "../../assets/icons/fluent/speaker-2-filled.svg";
            }
        }

        ColorOverlay {
            anchors.fill: volIcon
            source: volIcon
            color: Appearance.colors.colOnLayer0
        }
    }

    
    Text {
        id: percentText
        text: (Audio.sink?.audio?.muted ? "Muted" : Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%")
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
            width: sliderTrack.width * (Audio.sink?.audio?.muted ? 0 : (Audio.sink?.audio?.volume ?? 0))
        }
    }
}
