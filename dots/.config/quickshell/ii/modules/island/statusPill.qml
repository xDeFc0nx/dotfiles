import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.services

Rectangle {
    id: statusPill
    visible: Battery.available || Network.connected
    
    height: 32
    width: Battery.available ? 72 : 40
    
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: Appearance.colors.colLayer1 
    radius: 16

    MouseArea {
        id: pillMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            islandWindow.controlCenterOpen = !islandWindow.controlCenterOpen
        }
    }

    states: State {
        name: "hovered"
        when: pillMouseArea.containsMouse
        PropertyChanges { 
            target: statusPill
            border.color: Appearance.colors.colPrimary
        }
    }

    transitions: Transition {
        from: ""
        to: "hovered"
        reversible: true
        ColorAnimation { property: "border.color"; duration: 200 }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6
        layoutDirection: Qt.RightToLeft

        Row {
            visible: Battery.available
            spacing: 3
            Text {
                text: (Battery.percentage !== undefined ? Math.floor(Battery.percentage * 100) : 0) + "%"
                color: Appearance.colors.colOnLayer0
                font.pixelSize: 11
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: 14
                height: 14
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: batteryImg
                    source: "../../assets/icons/fluent/battery-full.svg"
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: batteryImg
                    source: batteryImg
                    color: Appearance.colors.colOnLayer0
                }
            }
        }

        Item {
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: networkImg
                source: Network.isEthernet
                    ? "../../assets/icons/fluent/ethernet-filled.svg" 
                    : "../../assets/icons/fluent/wifi-" + (Network.strength || "4") + "-filled.svg"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            ColorOverlay {
                anchors.fill: networkImg
                source: networkImg
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
