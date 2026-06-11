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
import qs.modules.ii.wallpaperSelector

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

                property bool launcherOpen: GlobalStates.overviewOpen

                onLauncherOpenChanged: {
                    isExpanded = false;
                    if (typeof island !== "undefined" && island.hoverDebounceTimer) {
                        island.hoverDebounceTimer.stop();
                    }
                }

                focusable: islandWindow.launcherOpen
                
                exclusiveZone: islandWindow.restHeight + 8
                
                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.keyboardFocus: islandWindow.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                
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

                Connections {
                    target: Audio.sink?.audio ?? null
                    
                    function onVolumeChanged() {
                        if (Audio.sink?.audio) {
                            var vol = Audio.sink.audio.volume;
                            if (Math.abs(vol - islandWindow.lastVolume) > 0.005) {
                                islandWindow.lastVolume = vol;
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
                            islandWindow.lastMuted = Audio.sink.audio.muted;
                            if (!islandWindow.controlCenterOpen && !islandWindow.launcherOpen) {
                                islandWindow.showingBrightness = false;
                                islandWindow.showingVolume = true;
                                volumeCloseTimer.restart();
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
                

                readonly property bool hideElements: isFlashing || showingNotification || showingVolume || showingBrightness

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
                            notification.appIcon || notification.image || "image:
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
                            "image:
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
                        NumberAnimation { target: flashOverlay; property: "width"; to: islandWindow.restWidth; duration: 220; easing.type: Easing.OutQuad }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.InQuad }
                    }
                    PropertyAction { target: flashOverlay; property: "width"; value: 0 }
                    PauseAnimation { duration: 60 }

                    PropertyAction { target: flashOverlay; property: "opacity"; value: 0.85 }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "width"; to: islandWindow.restWidth; duration: 220; easing.type: Easing.OutQuad }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.InQuad }
                    }
                    PropertyAction { target: flashOverlay; property: "width"; value: 0 }
                    PauseAnimation { duration: 40 }

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
                    interval: 300
                    repeat: false
                    onTriggered: {
                        islandWindow.showingNotification = false;
                        islandWindow.activeNotification = null;
                    }
                }

                
                readonly property int targetWindowWidth: launcherOpen ? (launcherWidth + 24) : ((islandWindow.showingVolume || islandWindow.showingBrightness) ? 324 : (islandWindow.hoverWidth + 64))
                readonly property int targetWindowHeight: controlCenterOpen ? (ccViewInstance.implicitHeight + 40) : (launcherOpen ? (launcherHeight + 24) : ((islandWindow.showingVolume || islandWindow.showingBrightness) ? 60 : islandWindow.hoverHeight + 24))

                property int windowWidth: restWidth + 64
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
                    interval: 110
                    repeat: false
                    onTriggered: {
                        windowWidth = targetWindowWidth;
                    }
                }

                Timer {
                    id: heightDelayTimer
                    interval: 110
                    repeat: false
                    onTriggered: {
                        windowHeight = targetWindowHeight;
                    }
                }

                Component.onCompleted: {
                    if (islandWindow.launcherOpen) {
                        GlobalFocusGrab.addDismissable(islandWindow);
                    }
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removeDismissable(islandWindow);
                }

                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        if (!GlobalStates.overviewOpen) {
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

                        Rectangle {
                            id: island
                            color: {
                                if (!Appearance.colors || !Appearance.colors.colLayer0 || !Appearance.colors.colPrimary)
                                    return "transparent";
                                var c1 = Appearance.colors.colPrimary;
                                var c2 = Appearance.colors.colLayer0;
                                var pct = 0.15;
                                return Qt.rgba(
                                    pct * c1.r + (1 - pct) * c2.r,
                                    pct * c1.g + (1 - pct) * c2.g,
                                    pct * c1.b + (1 - pct) * c2.b,
                                    0.81
                                );
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
                                if (islandWindow.launcherOpen)
                                    return islandWindow.launcherWidth;
                                if (islandWindow.showingVolume || islandWindow.showingBrightness)
                                    return 300;
                                if (!islandWindow.isExpanded)
                                    return islandWindow.restWidth;
                                return islandWindow.hoverWidth;
                            }
                            
                            
                            height: {
                                if (islandWindow.launcherOpen)
                                    return islandWindow.launcherHeight;
                                if (islandWindow.showingVolume || islandWindow.showingBrightness)
                                    return 36;
                                if (!islandWindow.isExpanded)
                                    return islandWindow.restHeight;
                                return islandWindow.controlCenterOpen ? ccViewInstance.implicitHeight : islandWindow.hoverHeight;
                            }
                            
                            radius: {
                                if (islandWindow.controlCenterOpen || islandWindow.launcherOpen)
                                    return 24;
                                return Math.min(24, height / 2);
                            }

                            readonly property alias hoverDebounceTimer: hoverDebounceTimer

                            
                            HoverHandler {
                                id: tideTrack
                                enabled: !islandWindow.launcherOpen
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
                                interval: 300
                                repeat: false
                                onTriggered: {
                                    islandWindow.isExpanded = false
                                }
                            }

                            
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton 
                                onWheel: (event) => {
                                    if ((islandWindow.isExpanded || islandWindow.showingVolume) && !islandWindow.controlCenterOpen && !islandWindow.showingNotification && !islandWindow.launcherOpen) {
                                        islandWindow.showingBrightness = false;
                                        islandWindow.triggerVolumeChange(event.angleDelta.y);
                                    }
                                }
                            }

                            Behavior on width {
                                SpringAnimation {
                                    spring: 7.0      
                                    damping: 1.0     
                                    epsilon: 0.1
                                }
                            }
                            Behavior on height {
                                SpringAnimation {
                                    spring: 7.0      
                                    damping: 1.0     
                                    epsilon: 0.1
                                }
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 4

                                RestView {
                                    id: restViewInstance
                                    width: islandWindow.restWidth
                                    height: islandWindow.restHeight
                                    anchors.centerIn: parent
                                    visible: opacity > 0 && !islandWindow.launcherOpen
                                    opacity: (islandWindow.isExpanded || islandWindow.launcherOpen || islandWindow.showingVolume || islandWindow.showingBrightness) ? 0.0 : 1.0
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
                                    visible: islandWindow.isFlashing && !islandWindow.isExpanded && !islandWindow.launcherOpen
                                }

                                HoverView {
                                    id: hoverViewInstance
                                    width: islandWindow.hoverWidth
                                    height: islandWindow.hoverHeight
                                    anchors.centerIn: parent
                                    visible: opacity > 0 && !islandWindow.launcherOpen
                                    opacity: (islandWindow.isExpanded && !islandWindow.controlCenterOpen && !islandWindow.showingNotification && !islandWindow.launcherOpen && !islandWindow.showingVolume && !islandWindow.showingBrightness) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                NotificationView {
                                    id: notificationViewInstance
                                    width: islandWindow.hoverWidth
                                    height: islandWindow.hoverHeight
                                    anchors.centerIn: parent
                                    visible: opacity > 0 && !islandWindow.launcherOpen
                                    opacity: (islandWindow.isExpanded && islandWindow.showingNotification && !islandWindow.launcherOpen && !islandWindow.showingVolume && !islandWindow.showingBrightness) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.InOutQuad } }
                                }

                                CommandCenterView {
                                    id: ccViewInstance
                                    islandWindow: islandWindow
                                    width: islandWindow.hoverWidth
                                    
                                    
                                    height: implicitHeight 
                                    
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: opacity > 0 && !islandWindow.launcherOpen
                                    opacity: (islandWindow.isExpanded && islandWindow.controlCenterOpen && !islandWindow.launcherOpen && !islandWindow.showingVolume && !islandWindow.showingBrightness) ? 1.0 : 0.0
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

                                VolumeView {
                                    id: volumeViewInstance
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: islandWindow.showingVolume ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.InOutQuad } }
                                }

                                BrightnessView {
                                    id: brightnessViewInstance
                                    anchors.fill: parent
                                    screen: islandWindow.screen
                                    visible: opacity > 0
                                    opacity: islandWindow.showingBrightness ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.InOutQuad } }
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
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { component: WallpaperSelector {} }
}
