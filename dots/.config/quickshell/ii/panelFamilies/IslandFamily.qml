pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

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
            
            exclusiveZone: IslandConstants.sizes["rest"].height + 12
            
            WlrLayershell.namespace: "quickshell:bar"
            
            anchors { top: true }
            
            implicitWidth: maskBoundingBox.width
            implicitHeight: maskBoundingBox.height
            color: "transparent"

            mask: Region { item: maskBoundingBox }

            property bool isExpanded: false
            property bool controlCenterOpen: false

            onIsExpandedChanged: {
                if (!isExpanded) {
                    controlCenterOpen = false
                }
            }

            Item {
                id: maskBoundingBox
                width: IslandConstants.sizes["hover"].width + 64
                height: islandWindow.controlCenterOpen ? 620 : IslandConstants.sizes["hover"].height + 24

                Rectangle {
                    anchors.fill: parent
                    color: "#01000000" 
                }

                HoverHandler {
                    id: tideTrack
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
                    interval: 400 
                    repeat: false
                    onTriggered: {
                        islandWindow.isExpanded = false
                    }
                }

                Item {
                    id: islandContainer
                    width: island.width
                    height: island.height + 4
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
                        border.width: 1
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
                            if (!islandWindow.isExpanded)
                                return IslandConstants.sizes["rest"].width;
                            return IslandConstants.sizes["hover"].width;
                        }
                        height: {
                            if (!islandWindow.isExpanded)
                                return IslandConstants.sizes["rest"].height;
                            return islandWindow.controlCenterOpen ? 580 : IslandConstants.sizes["hover"].height;
                        }
                        radius: islandWindow.controlCenterOpen ? 24 : height / 2

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
                        }
                        Behavior on height {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 4

                            RestView {
                                id: restViewInstance
                                anchors.fill: parent
                                visible: opacity > 0
                                opacity: islandWindow.isExpanded ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                            }

                            HoverView {
                                id: hoverViewInstance
                                anchors.fill: parent
                                visible: opacity > 0
                                opacity: (islandWindow.isExpanded && !islandWindow.controlCenterOpen) ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                            }

                            CommandCenterView {
                                id: ccViewInstance
                                islandWindow: islandWindow
                                anchors.fill: parent
                                visible: opacity > 0
                                opacity: (islandWindow.isExpanded && islandWindow.controlCenterOpen) ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                            }
                        }
                    }
                }
            }
        }
    }
}

PanelLoader { component: Background {} }
PanelLoader { component: Cheatsheet {} }
PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
PanelLoader { component: Lock {} }
PanelLoader { component: MediaControls {} }
PanelLoader { component: OnScreenKeyboard {} }
PanelLoader { component: Overlay {} }
PanelLoader { component: Overview {} }
PanelLoader { component: RegionSelector {} }
PanelLoader { component: ScreenCorners {} }
PanelLoader { component: ScreenTranslator {} }
PanelLoader { component: SessionScreen {} }
PanelLoader { component: SidebarLeft {} }
PanelLoader { component: SidebarRight {} }
PanelLoader { component: WallpaperSelector {} }
}
