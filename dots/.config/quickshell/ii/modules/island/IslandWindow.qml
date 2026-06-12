// modules/island/IslandWindow.qml
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
import qs.modules.island.services

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

PanelWindow {
    id: islandWindow
    required property ShellScreen screen
    exclusionMode: ExclusionMode.Exclusive
    
    property int hoverWidth: 490  
    property int hoverHeight: 86
    property int restWidth: IslandConstants.sizes["rest"].width + 10
    property int restHeight: IslandConstants.sizes["rest"].height + 2
    property int launcherWidth: 420
    property int launcherHeight: launcherViewInstance.implicitHeight + 8

    property bool launcherOpen: GlobalStates.overviewOpen
    property bool controlCenterOpen: false
    property bool showingVolume: false
    property bool showingBrightness: false

    onLauncherOpenChanged: {
        IslandStateManager.isExpanded = false;
        IslandStateManager.hoverDebounceTimer.stop();
    }

    focusable: launcherOpen
    exclusiveZone: restHeight + 8
    
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    anchors { top: true }
    implicitWidth: 600
    implicitHeight: 800  
    color: "transparent"
    mask: Region { item: maskBoundingBox }

    Timer {
        id: volumeCloseTimer
        interval: 1500
        repeat: false
        onTriggered: showingVolume = false
    }

    Connections {
        target: Audio.sink?.audio
        function onVolumeChanged() { 
            if (!controlCenterOpen && !launcherOpen) {
                showingBrightness = false;
                showingVolume = true;
                volumeCloseTimer.restart();
            }
        }
    }

    Item {
        id: maskBoundingBox
        width: restWidth + 64
        height: restHeight + 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

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
                    return Qt.rgba(0.15 * c1.r + 0.85 * c2.r, 0.15 * c1.g + 0.85 * c2.g, 0.15 * c1.b + 0.85 * c2.b, 0.81);
                }
                
                clip: true
                radius: (controlCenterOpen || launcherOpen) ? 24 : Math.min(24, height / 2)
                width: launcherOpen ? launcherWidth : (showingVolume ? 300 : (IslandStateManager.isExpanded ? hoverWidth : restWidth))
                height: launcherOpen ? launcherHeight : (showingVolume ? 36 : (IslandStateManager.isExpanded ? (controlCenterOpen ? ccViewInstance.implicitHeight : hoverHeight) : restHeight))

                Behavior on width { SpringAnimation { spring: 7.0; damping: 1.0; epsilon: 0.1 } }
                Behavior on height { SpringAnimation { spring: 7.0; damping: 1.0; epsilon: 0.1 } }

                HoverHandler {
                    enabled: !launcherOpen
                    onHoveredChanged: {
                        if (hovered) {
                            IslandStateManager.hoverDebounceTimer.stop()
                            IslandStateManager.isExpanded = true
                        } else {
                            IslandStateManager.hoverDebounceTimer.start()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (IslandStateManager.isExpanded && !launcherOpen) {
                            controlCenterOpen = !controlCenterOpen
                        }
                    }
                }

                RestView { 
                    width: restWidth; height: restHeight; anchors.centerIn: parent
                    visible: !IslandStateManager.isExpanded && !launcherOpen && !showingVolume
                }
                
                HoverView {
                    width: hoverWidth; height: hoverHeight; anchors.centerIn: parent
                    visible: IslandStateManager.isExpanded && !controlCenterOpen && !launcherOpen && !showingVolume
                }

                CommandCenterView {
                    id: ccViewInstance
                    islandWindow: islandWindow
                    visible: controlCenterOpen
                }

                LauncherView {
                    id: launcherViewInstance
                    islandWindow: islandWindow
                    visible: launcherOpen
                }

                VolumeView {
                    visible: showingVolume
                }
            }
        }
    }
}
