import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.services

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    function getNextPrayer() {
        var now = new Date();
        var timings = PrayerTimes.timings;
        if (!timings || Object.keys(timings).length === 0) return Translation.tr("Prayers...");

        var mainPrayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
        var minDiff = 86400000;
        var prayerName = "";

        for (var i = 0; i < mainPrayers.length; i++) {
            var p = mainPrayers[i];
            if (!timings[p]) continue;

            var timeParts = timings[p].split(":");
            var prayerTime = new Date();
            prayerTime.setHours(timeParts[0]);
            prayerTime.setMinutes(timeParts[1]);
            prayerTime.setSeconds(0);

            var diff = prayerTime - now;
            if (diff > 0 && diff < minDiff) {
                minDiff = diff;
                prayerName = p;
            }
        }

        // Fallback to tomorrow's Fajr if Isha passed
        if (prayerName === "" && timings["Fajr"]) {
            var timeParts = timings["Fajr"].split(":");
            var prayerTime = new Date();
            prayerTime.setDate(prayerTime.getDate() + 1);
            prayerTime.setHours(timeParts[0]);
            prayerTime.setMinutes(timeParts[1]);
            prayerTime.setSeconds(0);
            minDiff = prayerTime - now;
            prayerName = "Fajr";
        }

        var totalMins = Math.floor(minDiff / 60000);
        var h = Math.floor(totalMins / 60);
        var m = totalMins % 60;
        return (prayerName || "Prayers") + " in " + (h > 0 ? h + "H " : "") + m + "M";
    }

    component StatusPill : Rectangle {
        id: statusPill
        visible: Battery.available || Network.connected || true
        
        height: 32
        width: pillRow.implicitWidth + 24
        
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

            // Weather addition
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
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 160
        spacing: 20

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: true

            Text {
                text: getNextPrayer()
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

        ColumnLayout {
            Layout.preferredWidth: 120
            Layout.alignment: Qt.AlignCenter
            spacing: 2

            Text {
                text: Qt.formatTime(new Date(), "HH:mm")
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: Qt.formatDate(new Date(), "ddd, MMM d")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: 12
                Layout.alignment: Qt.AlignCenter
            }
        }
        
        Item { Layout.fillWidth: true }
    }

    StatusPill {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
    }
}
