import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: btn
    property string title: ""
    property string subtext: ""
    property string iconSource: ""
    property bool active: false
    property var onClickedCallback: null
    property var onRightClickedCallback: null

    Layout.fillWidth: true
    height: 52
    radius: 16
    color: active ? Appearance.colors.colPrimary : Appearance.colors.colLayer1

    function textColor(activeState) {
        if (activeState) {
            if (Appearance.colors && Appearance.colors.colOnPrimary)
                return Appearance.colors.colOnPrimary
            var p = Appearance.colors.colPrimary
            var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b)
            return l > 0.5 ? "#1a120b" : "#ffffff"
        }
        return Appearance.colors.colOnLayer0
    }

    function subtextColor(activeState) {
        if (activeState) {
            if (Appearance.colors && Appearance.colors.colOnPrimary)
                return Qt.rgba(Appearance.colors.colOnPrimary.r, Appearance.colors.colOnPrimary.g, Appearance.colors.colOnPrimary.b, 0.7)
            var p = Appearance.colors.colPrimary
            var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b)
            return l > 0.5 ? "rgba(26, 18, 11, 0.7)" : "rgba(255, 255, 255, 0.7)"
        }
        return Appearance.colors.colOnSurfaceVariant
    }

    function iconOverlayColor(activeState) {
        if (activeState) {
            if (Appearance.colors && Appearance.colors.colOnPrimary)
                return Appearance.colors.colOnPrimary
            var p = Appearance.colors.colPrimary
            var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b)
            return l > 0.5 ? "#1a120b" : "#ffffff"
        }
        return Appearance.colors.colOnLayer0
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (onRightClickedCallback) onRightClickedCallback()
            } else {
                if (onClickedCallback) onClickedCallback()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: btn.active ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(255, 255, 255, 0.08)

            Image {
                id: btnIcon
                source: btn.iconSource
                anchors.fill: parent
                anchors.margins: 8
                fillMode: Image.PreserveAspectFit
            }
            ColorOverlay {
                anchors.fill: btnIcon
                source: btnIcon
                color: iconOverlayColor(btn.active)
            }
        }

        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true

            Text {
                text: btn.title
                color: textColor(btn.active)
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: btn.subtext
                color: subtextColor(btn.active)
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}