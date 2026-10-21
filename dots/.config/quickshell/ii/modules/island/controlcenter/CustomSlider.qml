import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: slider
    property real value: 0.5
    property string iconSource: ""
    property var onValueChangedCallback: null

    Layout.fillWidth: true
    height: 36
    radius: 18
    color: Appearance.colors.colLayer1

    Rectangle {
        id: fillArea
        width: slider.width * slider.value
        height: parent.height
        radius: parent.radius
        color: Appearance.colors.colPrimary

        Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: iconCircle
        width: 28
        height: 28
        radius: 14
        color: "transparent"
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: sIcon
            source: slider.iconSource
            anchors.fill: parent
            anchors.margins: 6
            fillMode: Image.PreserveAspectFit
        }
        ColorOverlay {
            anchors.fill: sIcon
            source: sIcon
            color: {
                if (slider.value > 0.08) {
                    if (Appearance.colors && Appearance.colors.colOnPrimary)
                        return Appearance.colors.colOnPrimary
                    var p = Appearance.colors.colPrimary
                    var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b)
                    return l > 0.5 ? "#1a120b" : "#ffffff"
                }
                return Appearance.colors.colOnLayer0
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function updateValue(mouse) {
            var val = Math.max(0, Math.min(1, mouse.x / slider.width))
            if (onValueChangedCallback) onValueChangedCallback(val)
        }

        onPressed: updateValue(mouse)
        onPositionChanged: updateValue(mouse)
        onWheel: (event) => {
            var step = event.angleDelta.y > 0 ? 0.05 : -0.05
            var newVal = Math.max(0, Math.min(1, slider.value + step))
            if (onValueChangedCallback) onValueChangedCallback(newVal)
        }
    }
}