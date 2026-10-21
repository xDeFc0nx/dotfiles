import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 140
    radius: 20
    color: Appearance.colors.colLayer1
    clip: true
    visible: MprisController.activePlayer !== null

    Timer {
        running: MprisController.activePlayer?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: MprisController.activePlayer?.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 44

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: MprisController.activePlayer?.trackTitle ?? "No music"
                        color: Appearance.colors.colOnLayer0
                        font.family: Appearance.fontFamily || "sans-serif"
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: MprisController.activePlayer?.trackArtist ?? "Unknown artist"
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: Appearance.fontFamily || "sans-serif"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: Appearance.colors.colLayer0

                Image {
                    id: playPauseIcon
                    source: MprisController.activePlayer?.isPlaying ? "../../../assets/icons/fluent/pause-filled.svg" : "../../../assets/icons/fluent/play-filled.svg"
                    anchors.fill: parent
                    anchors.margins: 12
                    fillMode: Image.PreserveAspectFit
                }
                ColorOverlay {
                    anchors.fill: playPauseIcon
                    source: playPauseIcon
                    color: Appearance.colors.colOnLayer0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MprisController.activePlayer?.togglePlaying()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: "transparent"

                Image {
                    id: prevIcon
                    source: "../../../assets/icons/fluent/previous-filled.svg"
                    anchors.fill: parent
                    anchors.margins: 8
                    fillMode: Image.PreserveAspectFit
                }
                ColorOverlay {
                    anchors.fill: prevIcon
                    source: prevIcon
                    color: Appearance.colors.colOnLayer0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MprisController.activePlayer?.previous()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Appearance.colors.colLayer0

                Rectangle {
                    width: progressWidth
                    height: parent.height
                    radius: parent.radius
                    color: Appearance.colors.colOnLayer0

                    Behavior on width {
                        NumberAnimation { duration: 1000; easing.type: Easing.Linear }
                    }
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: "transparent"

                Image {
                    id: nextIcon
                    source: "../../../assets/icons/fluent/next-filled.svg"
                    anchors.fill: parent
                    anchors.margins: 8
                    fillMode: Image.PreserveAspectFit
                }
                ColorOverlay {
                    anchors.fill: nextIcon
                    source: nextIcon
                    color: Appearance.colors.colOnLayer0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MprisController.activePlayer?.next()
                }
            }
        }
    }

    readonly property real progressWidth: {
        if (MprisController.activePlayer && MprisController.activePlayer.length > 0) {
            var pos = MprisController.activePlayer.position || 0
            var len = MprisController.activePlayer.length
            return (pos / len) * parent.width
        }
        return 0
    }
}