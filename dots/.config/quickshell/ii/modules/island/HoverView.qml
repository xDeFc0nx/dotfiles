import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.services
import Quickshell

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    // Properties passed from IslandFamily.qml to avoid dynamic scope resolution failures
    property bool isRecordingActive: false
    property string recordingElapsedText: "00:00"

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
        
        height: 38
        width: pillRow.implicitWidth + 28
        
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

        radius: 19

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

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8
            layoutDirection: Qt.RightToLeft

            RowLayout {
                id: batteryRow
                visible: Battery.available
                spacing: 3
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    text: (Battery.percentage !== undefined ? Math.floor(Battery.percentage * 100) : 0) + "%"
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: 13
                    font.bold: true
                    height: 20
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    width: 20
                    height: 20
                    Layout.alignment: Qt.AlignVCenter

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
                width: 20
                height: 20
                Layout.alignment: Qt.AlignVCenter

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

            RowLayout {
                id: weatherRow
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: (Weather.data.temp || "--")
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: 13
                    font.bold: true
                    height: 20                            
                    verticalAlignment: Text.AlignVCenter  
                    Layout.alignment: Qt.AlignVCenter
                }
                
                Item {
                    width: 20
                    height: 20
                    Layout.alignment: Qt.AlignVCenter
                    
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

    Row {
        id: prayerInfoRow
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 4

        opacity: root.isFullyExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        Item {
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: sunPositionImg
                source: {
                    var name = PrayerTimes.nextPrayerData.name; 
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
                visible: false 
            }

            ColorOverlay {
                anchors.fill: sunPositionImg
                source: sunPositionImg
                color: Appearance.colors.colOnLayer0
            }
        }

        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: PrayerTimes.nextPrayerData.countdown
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                text: PrayerTimes.nextPrayerData.name
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 12
            }
        }
    }

    // Wrapped in a normal Item container so anchors on the MouseArea do not conflict with the layout engine
    Item {
        anchors.centerIn: parent
        width: clockLayout.implicitWidth
        height: clockLayout.implicitHeight

        ColumnLayout {
            id: clockLayout
            anchors.fill: parent
            spacing: 2

            Text {
                text: root.isRecordingActive ? root.recordingElapsedText : Qt.formatTime(root.currentDateTime, "HH:mm")
                color: root.isRecordingActive ? "#ff4f4f" : Appearance.colors.colOnLayer0
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignCenter

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            Text {
                text: root.isRecordingActive ? "REC" : Qt.formatDate(root.currentDateTime, "ddd, MMM d")
                color: root.isRecordingActive ? "#ff4f4f" : Appearance.colors.colOnSurfaceVariant
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 12
                font.bold: root.isRecordingActive
                Layout.alignment: Qt.AlignCenter

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.isRecordingActive
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // Iterates natively and terminates active recorders, including OBS (graceful exit saves files safely)
                const recorders = ["wf-recorder", "wl-screenrec", "gpu-screen-recorder", "obs"];
                for (var i = 0; i < recorders.length; i++) {
                    Quickshell.execDetached(["pkill", "-SIGINT", "-x", recorders[i]]);
                }
            }
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
