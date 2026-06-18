pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.island

import qs.modules.ii.background
import qs.modules.ii.cheatsheet
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay

Scope {
    id: islandFamily

    Component.onCompleted: {
        var initAudio = AudioReminders;
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        
        LazyLoader {
            id: islandLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            
            component: PanelWindow {
                id: islandWindow
                screen: islandLoader.modelData
                
                exclusionMode: ExclusionMode.Exclusive
                
                property int hoverWidth: 490  
                property int hoverHeight: 86

                property int restWidth: IslandConstants.sizes["rest"].width + 10
                property int restHeight: IslandConstants.sizes["rest"].height + 2

                property int launcherWidth: 420
                property int launcherHeight: launcherViewInstance.implicitHeight + 8

                property int wallpaperWidth: 420
                property int wallpaperHeight: 360

                property int sessionWidth: 460
                property int sessionHeight: 108

                property int polkitWidth: 460
                property int polkitHeight: 180

                property bool launcherOpen: GlobalStates.overviewOpen
                property bool wallpaperSelectorOpen: GlobalStates.wallpaperSelectorOpen
                property bool sessionOpen: GlobalStates.sessionOpen
                property bool polkitOpen: PolkitService.active

                property bool isRecordingActive: false
                property int recordingElapsedSeconds: 0
                property string recordingElapsedText: "00:00"

                Timer {
                    id: recordingTimer
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        if (!recordingProcessChecker.running) {
                            recordingProcessChecker.running = true;
                        }
                        if (islandWindow.isRecordingActive) {
                            islandWindow.recordingElapsedSeconds++
                            var m = Math.floor(islandWindow.recordingElapsedSeconds / 60)
                            var s = islandWindow.recordingElapsedSeconds % 60
                            islandWindow.recordingElapsedText = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
                        }
                    }
                }

                Process {
                    id: recordingProcessChecker
                    command: ["bash", "-c", "pgrep -x wf-recorder || pgrep -x wl-screenrec || pgrep -x gpu-screen-recorder || (PID=$(pgrep -x obs) && ls -l /proc/$PID/fd/ 2>/dev/null | grep -E '\\.(mp4|mkv|flv|mov|ts|webm)$')"]
                    onExited: (exitCode) => {
                        var running = (exitCode === 0)
                        if (running !== islandWindow.isRecordingActive) {
                            islandWindow.isRecordingActive = running
                            if (running) {
                                islandWindow.recordingElapsedSeconds = 0;
                                islandWindow.recordingElapsedText = "00:00";
                            }
                        }
                    }
                }

                onLauncherOpenChanged: {
                    isExpanded = false;
                    if (typeof island !== "undefined" && island.hoverDebounceTimer) {
                        island.hoverDebounceTimer.stop();
                    }
                }

                onWallpaperSelectorOpenChanged: {
                    isExpanded = false;
                    if (typeof island !== "undefined" && island.hoverDebounceTimer) {
                        island.hoverDebounceTimer.stop();
                    }
                }

                onSessionOpenChanged: {
                    isExpanded = false;
                    if (typeof island !== "undefined" && island.hoverDebounceTimer) {
                        island.hoverDebounceTimer.stop();
                    }
                }

                onPolkitOpenChanged: {
                    isExpanded = false;
                    if (typeof island !== "undefined" && island.hoverDebounceTimer) {
                        island.hoverDebounceTimer.stop();
                    }
                }

                focusable: islandWindow.launcherOpen || islandWindow.wallpaperSelectorOpen || islandWindow.sessionOpen || islandWindow.polkitOpen
                
                exclusiveZone: islandWindow.restHeight + 8
                
                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.keyboardFocus: (islandWindow.launcherOpen || islandWindow.wallpaperSelectorOpen || islandWindow.sessionOpen || islandWindow.polkitOpen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                
                anchors { top: true }
                
                implicitWidth: 600
                implicitHeight: 800  
                color: "transparent"

                mask: Region { item: maskBoundingBox }

                property bool isExpanded: false
                property bool controlCenterOpen: false

                property bool showingNotification: false
                property var activeNotification: null
                property real islandBorderWidth: 1.0

                property bool isFlashing: false
                property color flashColor: "#00ffffff"

                property bool showingVolume: false

                Timer {
                    id: volumeCloseTimer
                    interval: 1500
                    repeat: false
                    onTriggered: {
                        islandWindow.showingVolume = false;
                    }
                }

                function triggerVolumeChange(delta) {
                    if (!Audio.sink?.audio) return;
                    
                    var currentVol = Audio.sink.audio.volume;
                    var step = delta > 0 ? 0.02 : -0.02;
                    var newVol = Math.max(0, Math.min(1, currentVol + step));
                    
                    Audio.sink.audio.volume = newVol;
                    
                    if (newVol > 0 && Audio.sink.audio.muted) {
                        Audio.sink.audio.muted = false;
                    }

                    islandWindow.showingBrightness = false;
                    islandWindow.showingVolume = true;
                    volumeCloseTimer.restart();
                }

                property real lastVolume: Audio.sink?.audio?.volume ?? 0.0
                property bool lastMuted: Audio.sink?.audio?.muted ?? false
                property bool systemReady: false

                Timer {
                    id: startupTimer
                    interval: 1500
                    running: true
                    repeat: false
                    onTriggered: {
                        islandWindow.systemReady = true;
                    }
                }

                Connections {
                    target: Audio.sink?.audio ?? null
                    
                    function onVolumeChanged() {
                        if (Audio.sink?.audio) {
                            var vol = Audio.sink.audio.volume;
                            var oldVol = islandWindow.lastVolume;
                            islandWindow.lastVolume = vol;
                            if (islandWindow.systemReady && Math.abs(vol - oldVol) > 0.005) {
                                if (!islandWindow.controlCenterOpen && !islandWindow.launcherOpen) {
                                    islandWindow.showingBrightness = false;
                                    islandWindow.showingVolume = true;
                                    volumeCloseTimer.restart();
                                }
                            }
                        }
                    }
                    
                    function onMutedChanged() {
                        if (Audio.sink?.audio) {
                            var muted = Audio.sink.audio.muted;
                            var oldMuted = islandWindow.lastMuted;
                            islandWindow.lastMuted = muted;
                            if (islandWindow.systemReady && muted !== oldMuted) {
                                if (!islandWindow.controlCenterOpen && !islandWindow.launcherOpen) {
                                    islandWindow.showingBrightness = false;
                                    islandWindow.showingVolume = true;
                                    volumeCloseTimer.restart();
                                }
                            }
                        }
                    }
                }

                property bool showingBrightness: false

                Timer {
                    id: brightnessCloseTimer
                    interval: 1500
                    repeat: false
                    onTriggered: {
                        islandWindow.showingBrightness = false;
                    }
                }

                function triggerBrightnessChange(delta) {
                    var monitor = Brightness.getMonitorForScreen(islandWindow.screen);
                    if (!monitor) return;
                    
                    var currentBright = monitor.brightness;
                    var step = delta > 0 ? 0.05 : -0.05;
                    var newBright = Math.max(0, Math.min(1, currentBright + step));
                    
                    monitor.setBrightness(newBright);

                    islandWindow.showingVolume = false;
                    islandWindow.showingBrightness = true;
                    brightnessCloseTimer.restart();
                }

                IpcHandler {
                    target: "brightness"
                    
                    function increment(): void {
                        islandWindow.triggerBrightnessChange(1);
                    }
                    
                    function decrement(): void {
                        islandWindow.triggerBrightnessChange(-1);
                    }
                }

                readonly property bool hideElements: isFlashing || showingNotification || showingVolume || showingBrightness || wallpaperSelectorOpen || sessionOpen || polkitOpen

                onShowingNotificationChanged: console.log("[IslandWindow] state showingNotification changed: " + showingNotification);
                
                onIsExpandedChanged: {
                    console.log("[IslandWindow] state isExpanded changed: " + isExpanded);
                    if (!isExpanded) {
                        controlCenterOpen = false;
                    }
                }

                Connections {
                    target: Notifications
                    function onNotify(notification) {
                        islandWindow.postNotification(
                            notification.summary,                                         
                            notification.body,                                            
                            notification.appIcon || notification.image || "image://icon/dialog-information",
                            notification.notificationId,
                            notification
                        );
                    }
                }

                GlobalShortcut {
                    name: "testNotification"
                    description: "Trigger a test notification"
                    onPressed: {
                        islandWindow.postNotification(
                            "Dynamic Island integration", 
                            "System notifications are successfully bound to the custom DBus singleton!", 
                            "image://icon/dialog-information",
                            99999,
                            null
                        );
                    }
                }

                function postNotification(title, body, icon, id, notification) {
                    notificationCloseTimer.stop();
                    resetStateTimer.stop();
                    flashAnim.stop();

                    islandWindow.activeNotification = {
                        title: title,
                        body: body,
                        icon: icon,
                        id: id
                    };

                    if (notification && typeof Colors !== "undefined" && typeof Colors.getIconColor === "function") {
                        islandWindow.flashColor = Colors.getIconColor(notification.appIcon || notification.image || "");
                    } else if (Appearance.colors && Appearance.colors.colPrimary) {
                        islandWindow.flashColor = Appearance.colors.colPrimary;
                    } else {
                        islandWindow.flashColor = "#ffffff";
                    }

                    islandWindow.isExpanded = false;
                    islandWindow.isFlashing = true;
                    flashAnim.start();
                }

                SequentialAnimation {
                    id: flashAnim
                    
                    PropertyAction { target: flashOverlay; property: "width"; value: 0 }
                    PropertyAction { target: flashOverlay; property: "opacity"; value: 0.85 }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "width"; to: islandWindow.restWidth; duration: 150; easing.type: Easing.OutQuad }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 120; easing.type: Easing.InQuad }
                    }
                    PropertyAction { target: flashOverlay; property: "width"; value: 0 }
                    PauseAnimation { duration: 40 }

                    PropertyAction { target: flashOverlay; property: "opacity"; value: 0.85 }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "width"; to: islandWindow.restWidth; duration: 150; easing.type: Easing.OutQuad }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 120; easing.type: Easing.InQuad }
                    }
                    PropertyAction { target: flashOverlay; property: "width"; value: 0 }
                    PauseAnimation { duration: 30 }

                    onFinished: {
                        islandWindow.isFlashing = false;
                        islandWindow.showingNotification = true;
                        islandWindow.isExpanded = true;
                        notificationCloseTimer.start();
                    }
                }

                Timer {
                    id: notificationCloseTimer
                    interval: 5000
                    repeat: false
                    onTriggered: {
                        islandWindow.isExpanded = false;
                        resetStateTimer.start();
                    }
                }

                Timer {
                    id: resetStateTimer
                    interval: 200
                    repeat: false
                    onTriggered: {
                        islandWindow.showingNotification = false;
                        islandWindow.activeNotification = null;
                    }
                }

                readonly property int targetWindowWidth: {
                    var baseWidth = 0;
                    if (polkitOpen)
                        baseWidth = polkitWidth + 24;
                    else if (sessionOpen)
                        baseWidth = sessionWidth + 24;
                    else if (wallpaperSelectorOpen)
                        baseWidth = wallpaperWidth + 24;
                    else if (launcherOpen)
                        baseWidth = launcherWidth + 24;
                    else if (showingVolume || showingBrightness)
                        baseWidth = 324;
                    else if (isExpanded)
                        baseWidth = hoverWidth + 64;
                    else
                        baseWidth = restWidth + 24;

                    if (isRecordingActive && !isExpanded && !launcherOpen && !wallpaperSelectorOpen && !sessionOpen) {
                        return baseWidth + 48;
                    }
                    return baseWidth;
                }

                readonly property int targetWindowHeight: {
                    if (controlCenterOpen)
                        return ccViewInstance.implicitHeight + 40;
                    if (polkitOpen)
                        return polkitHeight + 24;
                    if (sessionOpen)
                        return sessionHeight + 24;
                    if (wallpaperSelectorOpen)
                        return wallpaperHeight + 24;
                    if (launcherOpen)
                        return launcherHeight + 24;
                    if (showingVolume || showingBrightness)
                        return 60;
                    if (isExpanded)
                        return hoverHeight + 24;
                    return restHeight + 24;
                }

                property int windowWidth: restWidth + 24
                property int windowHeight: restHeight + 24

                onTargetWindowWidthChanged: {
                    if (targetWindowWidth > windowWidth) {
                        widthDelayTimer.stop();
                        windowWidth = targetWindowWidth;
                    } else {
                        widthDelayTimer.restart();
                    }
                }

                onTargetWindowHeightChanged: {
                    if (targetWindowHeight > windowHeight) {
                        heightDelayTimer.stop();
                        windowHeight = targetWindowHeight;
                    } else {
                        heightDelayTimer.restart();
                    }
                }

                Timer {
                    id: widthDelayTimer
                    interval: 70
                    repeat: false
                    onTriggered: {
                        windowWidth = targetWindowWidth;
                    }
                }

                Timer {
                    id: heightDelayTimer
                    interval: 70
                    repeat: false
                    onTriggered: {
                        windowHeight = targetWindowHeight;
                    }
                }

                Component.onCompleted: {
                    if (islandWindow.launcherOpen || islandWindow.wallpaperSelectorOpen || islandWindow.sessionOpen || islandWindow.polkitOpen) {
                        GlobalFocusGrab.addDismissable(islandWindow);
                    }
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removeDismissable(islandWindow);
                }

                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        if (!GlobalStates.overviewOpen && !GlobalStates.wallpaperSelectorOpen && !GlobalStates.sessionOpen && !PolkitService.active) {
                            GlobalFocusGrab.removeDismissable(islandWindow);
                        } else {
                            GlobalFocusGrab.addDismissable(islandWindow);
                        }
                    }
                    function onWallpaperSelectorOpenChanged() {
                        if (!GlobalStates.overviewOpen && !GlobalStates.wallpaperSelectorOpen && !GlobalStates.sessionOpen && !PolkitService.active) {
                            GlobalFocusGrab.removeDismissable(islandWindow);
                        } else {
                            GlobalFocusGrab.addDismissable(islandWindow);
                        }
                    }
                    function onSessionOpenChanged() {
                        if (!GlobalStates.overviewOpen && !GlobalStates.wallpaperSelectorOpen && !GlobalStates.sessionOpen && !PolkitService.active) {
                            GlobalFocusGrab.removeDismissable(islandWindow);
                        } else {
                            GlobalFocusGrab.addDismissable(islandWindow);
                        }
                    }
                }

                Connections {
                    target: PolkitService
                    function onActiveChanged() {
                        if (!GlobalStates.overviewOpen && !GlobalStates.wallpaperSelectorOpen && !GlobalStates.sessionOpen && !PolkitService.active) {
                            GlobalFocusGrab.removeDismissable(islandWindow);
                        } else {
                            GlobalFocusGrab.addDismissable(islandWindow);
                        }
                    }
                }

                Connections {
                    target: GlobalFocusGrab
                    function onDismissed() {
                        GlobalStates.overviewOpen = false;
                        GlobalStates.wallpaperSelectorOpen = false;
                        GlobalStates.sessionOpen = false;
                        if (PolkitService.active) {
                            PolkitService.cancel();
                        }
                    }
                }

                Item {
                    id: maskBoundingBox
                    width: islandWindow.windowWidth
                    height: islandWindow.windowHeight
                    
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    Rectangle {
                        anchors.fill: parent
                        color: "#01000000" 
                    }

                    Item {
                        id: islandContainer
                        width: island.width
                        height: island.height + 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Circular Recording Indicator (Separate floating shape on the left)
                        Rectangle {
                            id: externalRecordButton
                            width: 32
                            height: 32
                            radius: 16
                            color: {
                                if (!Appearance.colors || !Appearance.colors.colLayer0 || !Appearance.colors.colPrimary)
                                    return "transparent";
                                var c1 = Appearance.colors.colPrimary;
                                var c2 = Appearance.colors.colLayer0;
                                var pct = 0.35;
                                return Qt.rgba(
                                    pct * c1.r + (1 - pct) * c2.r,
                                    pct * c1.g + (1 - pct) * c2.g,
                                    pct * c1.b + (1 - pct) * c2.b,
                                    0.92
                                );
                            }

                            border.width: islandWindow.islandBorderWidth
                            border.color: island.border.color

                            anchors.right: island.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: island.verticalCenter

                            visible: islandWindow.isRecordingActive && !islandWindow.isExpanded && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen

                            Rectangle {
                                id: redDot
                                width: 12
                                height: 12
                                radius: 6
                                color: "#ff4f4f"
                                anchors.centerIn: parent

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutQuad }
                                    NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
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

                        Rectangle {
                            id: island
                            
                            color: {
                                if (!Appearance.colors || !Appearance.colors.colLayer0 || !Appearance.colors.colPrimary)
                                    return "transparent";
                                var c1 = Appearance.colors.colPrimary;
                                var c2 = Appearance.colors.colLayer0;
                                var pct = 0.35;
                                return Qt.rgba(
                                    pct * c1.r + (1 - pct) * c2.r,
                                    pct * c1.g + (1 - pct) * c2.g,
                                    pct * c1.b + (1 - pct) * c2.b,
                                    0.92
                                );
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: 350; easing.type: Easing.InOutQuad }
                            }

                            border.width: islandWindow.islandBorderWidth
                            border.color: {
                                if (!Appearance.colors || !Appearance.colors.colLayer0 || !Appearance.colors.colOnLayer0)
                                    return "transparent";
                                var isDark = Appearance.colors.colLayer0.hslLightness < 0.5;
                                if (isDark) {
                                    var c = Appearance.colors.colOnLayer0;
                                    return Qt.rgba(c.r, c.g, c.b, 0.15);
                                }
                                return "transparent";
                            }

                            clip: true
                            y: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            width: {
                                if (islandWindow.polkitOpen)
                                    return islandWindow.polkitWidth;
                                if (islandWindow.sessionOpen)
                                    return islandWindow.sessionWidth;
                                if (islandWindow.wallpaperSelectorOpen)
                                    return islandWindow.wallpaperWidth;
                                if (islandWindow.launcherOpen)
                                    return islandWindow.launcherWidth;
                                if (islandWindow.showingVolume || islandWindow.showingBrightness)
                                    return 300;
                                if (!islandWindow.isExpanded)
                                    return islandWindow.restWidth;
                                return islandWindow.hoverWidth;
                            }
                            
                            height: {
                                if (islandWindow.polkitOpen)
                                    return islandWindow.polkitHeight;
                                if (islandWindow.sessionOpen)
                                    return islandWindow.sessionHeight;
                                if (islandWindow.wallpaperSelectorOpen)
                                    return islandWindow.wallpaperHeight;
                                if (islandWindow.launcherOpen)
                                    return islandWindow.launcherHeight;
                                if (islandWindow.showingVolume || islandWindow.showingBrightness)
                                    return 36;
                                if (!islandWindow.isExpanded)
                                    return islandWindow.restHeight;
                                return islandWindow.controlCenterOpen ? ccViewInstance.implicitHeight : islandWindow.hoverHeight;
                            }
                            
                            radius: {
                                if (islandWindow.polkitOpen || islandWindow.sessionOpen || islandWindow.wallpaperSelectorOpen || islandWindow.controlCenterOpen || islandWindow.launcherOpen)
                                    return 24;
                                return Math.min(24, height / 2);
                            }

                            readonly property alias hoverDebounceTimer: hoverDebounceTimer

                            HoverHandler {
                                id: tideTrack
                                enabled: !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen
                                onHoveredChanged: {
                                    if (hovered) {
                                        hoverDebounceTimer.stop()
                                        islandWindow.isExpanded = true
                                    } else {
                                        hoverDebounceTimer.start()
                                    }
                                }
                            }

                            Timer {
                                id: hoverDebounceTimer
                                interval: 150 
                                repeat: false
                                onTriggered: {
                                    islandWindow.isExpanded = false
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton 
                                onWheel: (event) => {
                                    if ((islandWindow.isExpanded || islandWindow.showingVolume) && !islandWindow.controlCenterOpen && !islandWindow.showingNotification && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen) {
                                        islandWindow.showingBrightness = false;
                                        islandWindow.triggerVolumeChange(event.angleDelta.y);
                                    }
                                }
                            }

                            Behavior on width {
                                SpringAnimation {
                                    spring: 15.0      
                                    damping: 1.0     
                                    epsilon: 0.1
                                }
                            }
                            Behavior on height {
                                SpringAnimation {
                                    spring: 15.0      
                                    damping: 1.0     
                                    epsilon: 0.1
                                }
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 4

                                RestView {
                                    id: restViewInstance
                                    isRecordingActive: islandWindow.isRecordingActive
                                    recordingElapsedText: islandWindow.recordingElapsedText
                                    width: islandWindow.restWidth
                                    height: islandWindow.restHeight
                                    anchors.centerIn: parent
                                    visible: opacity > 0 && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen
                                    opacity: (islandWindow.isExpanded || islandWindow.launcherOpen || islandWindow.showingVolume || islandWindow.showingBrightness || islandWindow.wallpaperSelectorOpen || islandWindow.sessionOpen || islandWindow.polkitOpen) ? 0.0 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                Rectangle {
                                    id: flashOverlay
                                    height: islandWindow.restHeight
                                    width: 0
                                    opacity: 0
                                    radius: island.radius
                                    color: islandWindow.flashColor
                                    anchors.centerIn: parent
                                    visible: islandWindow.isFlashing && !islandWindow.isExpanded && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen
                                }

                                HoverView {
                                    id: hoverViewInstance
                                    isRecordingActive: islandWindow.isRecordingActive
                                    recordingElapsedText: islandWindow.recordingElapsedText
                                    width: islandWindow.hoverWidth
                                    height: islandWindow.hoverHeight
                                    anchors.centerIn: parent
                                    visible: opacity > 0 && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen
                                    opacity: (islandWindow.isExpanded && !islandWindow.controlCenterOpen && !islandWindow.showingNotification && !islandWindow.launcherOpen && !islandWindow.showingVolume && !islandWindow.showingBrightness && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                NotificationView {
                                    id: notificationViewInstance
                                    width: islandWindow.hoverWidth
                                    height: islandWindow.hoverHeight
                                    anchors.centerIn: parent
                                    visible: opacity > 0 && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen
                                    opacity: (islandWindow.isExpanded && islandWindow.showingNotification && !islandWindow.launcherOpen && !islandWindow.showingVolume && !islandWindow.showingBrightness && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                CommandCenterView {
                                    id: ccViewInstance
                                    islandWindow: islandWindow
                                    width: islandWindow.hoverWidth
                                    height: implicitHeight 
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: opacity > 0 && !islandWindow.launcherOpen && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen
                                    opacity: (islandWindow.isExpanded && islandWindow.controlCenterOpen && !islandWindow.launcherOpen && !islandWindow.showingVolume && !islandWindow.showingBrightness && !islandWindow.wallpaperSelectorOpen && !islandWindow.sessionOpen && !islandWindow.polkitOpen) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                LauncherView {
                                    id: launcherViewInstance
                                    islandWindow: islandWindow
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: islandWindow.launcherOpen ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                WallpaperView {
                                    id: wallpaperViewInstance
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: islandWindow.wallpaperSelectorOpen ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                PowerMenuView {
                                    id: powerMenuViewInstance
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: islandWindow.sessionOpen ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                PolkitView {
                                    id: polkitViewInstance
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: islandWindow.polkitOpen ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                VolumeView {
                                    id: volumeViewInstance
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: islandWindow.showingVolume ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                BrightnessView {
                                    id: brightnessViewInstance
                                    anchors.fill: parent
                                    screen: islandWindow.screen
                                    visible: opacity > 0
                                    opacity: islandWindow.showingBrightness ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property bool dontAutoCancelSearch: false

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && islandFamily.dontAutoCancelSearch && LauncherSearch.query === Config.options.search.prefix.clipboard) {
            GlobalStates.overviewOpen = false;
            return;
        }
        islandFamily.dontAutoCancelSearch = true;
        LauncherSearch.query = Config.options.search.prefix.clipboard;
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && islandFamily.dontAutoCancelSearch && LauncherSearch.query === Config.options.search.prefix.emojis) {
            GlobalStates.overviewOpen = false;
            return;
        }
        islandFamily.dontAutoCancelSearch = true;
        LauncherSearch.query = Config.options.search.prefix.emojis;
        GlobalStates.overviewOpen = true;
    }

    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"
        onPressed: {
            islandFamily.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"
        onPressed: {
            islandFamily.toggleEmojis();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"
        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"
        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"
        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }
    }

    GlobalShortcut {
        name: "sessionToggle"
        description: "Toggle session / power menu"
        onPressed: {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }
    }

    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    
    PanelLoader { 
        extraCondition: !GlobalStates.barOpen 
        component: SessionScreen {} 
    }
    
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
}
