import QtQuick
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.services

Item {
    id: root
    
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    readonly property var screen: root.QsWindow.window?.screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    property int activeWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    property bool showingWorkspace: false

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (Hyprland.focusedMonitor?.name === monitor?.name) {
                root.activeWorkspaceId = Hyprland.focusedWorkspace.id;
                root.showingWorkspace = true;
                workspaceTimer.restart();
            }
        }
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            if (ToplevelManager.activeToplevel && Hyprland.focusedMonitor?.name === monitor?.name) {
                root.showingWorkspace = true;
                workspaceTimer.restart();
            }
        }
    }

    Timer {
        id: workspaceTimer
        interval: 3000
        onTriggered: showingWorkspace = false
    }

    property int displayMode: 0 // 0: Time, 1: Weather, 2: Prayer
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: displayMode = (displayMode + 1) % 3
    }

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

    function getDisplayText() {
        if (displayMode === 0) return DateTime.time;
        if (displayMode === 1) return (Weather.data.temp || "--") + " " + (Weather.data.city || "");
        if (displayMode === 2) return getNextPrayer();
        return DateTime.time;
    }

    // Main Info View
    Row {
        id: infoView
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2 
        opacity: showingWorkspace ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: getDisplayText()
            color: (Appearance.colors && Appearance.colors.colOnLayer0) || "white"
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: root.displayMode === 0 ? 20 : 14
            font.bold: root.displayMode === 0
            
            Behavior on font.pixelSize {
                NumberAnimation { duration: 200 }
            }
        }
    }

    // Workspace Indicator View (end4 style)
    Row {
        id: workspacesView
        anchors.centerIn: parent
        spacing: 6
        opacity: showingWorkspace ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Repeater {
            model: 5
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: (root.activeWorkspaceId === index + 1) ? Appearance.colors.colPrimary : "transparent"
                
                property bool isOccupied: Hyprland.workspaces.values.some(ws => ws.id === index + 1)

                Text {
                    anchors.centerIn: parent
                    text: index + 1
                    color: (root.activeWorkspaceId === index + 1) 
                        ? Appearance.colors.colOnPrimary 
                        : (parent.isOccupied ? Appearance.colors.colOnLayer0 : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4))
                    font.family: Appearance.fontFamily || "sans-serif"
                    font.pixelSize: 14
                    font.bold: root.activeWorkspaceId === index + 1
                }
            }
        }
    }
}
