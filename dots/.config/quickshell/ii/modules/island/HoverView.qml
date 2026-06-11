import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.services

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    
    property var currentDateTime: new Date()

    
    readonly property bool isFullyExpanded: width >= 400

    Timer {
        id: clockUpdateTimer
        interval: 1000 
        running: true
        repeat: true
        onTriggered: root.currentDateTime = new Date()
    }

    component StatusPill : Rectangle {
        id: statusPill
        visible: Battery.available || Network.connected || true
        
        height: 32
        width: pillRow.implicitWidth + 24
        
        
        color: {
            if (!Appearance.colors || !Appearance.colors.colLayer0)
                return Qt.rgba(0, 0, 0, 0.25);
            var isDark = Appearance.colors.colLayer0.hslLightness < 0.5;
            return isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(255, 255, 255, 0.35);
        }

        border.width: 1

        
        border.color: {
            if (!Appearance.colors || !Appearance.colors.colLayer0)
                return Qt.rgba(255, 255, 255, 0.05);
            var isDark = Appearance.colors.colLayer0.hslLightness < 0.5;
            return isDark ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.08);
        }

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
            id: pillRow
            anchors.centerIn: parent
            spacing: 8
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

            
            Row {
                spacing: 4
                Text {
                    text: (Weather.data.temp || "--")
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
                        id: weatherImg
                        source: "../../assets/icons/fluent/weather-sunny-filled.svg"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: weatherImg
                        source: weatherImg
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }
    }

    
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width / 2 - 80 
        spacing: 8
        clip: true

        
        opacity: root.isFullyExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        
        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: sunPositionImg
                source: {
                    var name = PrayerTimes.nextPrayerStr.split(" ")[0]; 
                    switch (name) {
                        case "Fajr":
                        case "Dhuhr":
                        case "Asr":
                            return "../../assets/icons/fluent/weather-sunny-filled.svg"; 
                        case "Maghrib":
                        case "Isha":
                            return "../../assets/icons/fluent/weather-moon-filled.svg";  
                        default:
                            return "../../assets/icons/fluent/weather-sunny-filled.svg";
                    }
                }
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                opacity: 0.0
            }

            ColorOverlay {
                anchors.fill: sunPositionImg
                source: sunPositionImg
                color: Appearance.colors.colOnLayer0
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: PrayerTimes.nextPrayerStr 
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: Translation.tr("Next Prayer")
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: Qt.formatTime(root.currentDateTime, "HH:mm")
            color: Appearance.colors.colOnLayer0
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignCenter
        }
        Text {
            text: Qt.formatDate(root.currentDateTime, "ddd, MMM d")
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: 12
            Layout.alignment: Qt.AlignCenter
        }
    }

    
    StatusPill {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter

        
        opacity: root.isFullyExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }
}
