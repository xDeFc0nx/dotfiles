import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    
    
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    property int activeWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    property bool showingWorkspace: false

    
    onActiveWorkspaceIdChanged: {
        root.showingWorkspace = true;
        workspaceTimer.restart();
    }

    
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            if (ToplevelManager.activeToplevel && HyprlandData.activeWorkspace?.monitor === monitor?.name) {
                root.showingWorkspace = true;
                workspaceTimer.restart();
            }
        }
    }

    Timer {
        id: workspaceTimer
        interval: 1000
        onTriggered: showingWorkspace = false
    }

    
    Text {
        id: infoText
        anchors.centerIn: parent
        text: DateTime.time
        color: Appearance.colors.colOnLayer0
        font.family: Appearance.fontFamily || "sans-serif"
        font.pixelSize: 16
        font.bold: true

        
        anchors.verticalCenterOffset: root.showingWorkspace ? -8 : 0
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        opacity: root.showingWorkspace ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    
    Item {
        id: workspacesContainer
        anchors.centerIn: parent
        width: 120  
        height: 32

        opacity: root.showingWorkspace ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        
        anchors.verticalCenterOffset: root.showingWorkspace ? 0 : 8
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        
        MouseArea {
            anchors.fill: parent
            onWheel: (event) => {
                if (event.angleDelta.y > 0) {
                    Hyprland.dispatch("workspace m-1"); 
                } else {
                    Hyprland.dispatch("workspace m+1"); 
                }
            }
        }

        ListView {
            id: listView
            anchors.fill: parent
            orientation: ListView.Horizontal
            interactive: false 
            clip: true         
            model: 10          
            
            
            currentIndex: Math.max(0, root.activeWorkspaceId - 1)

            
            preferredHighlightBegin: width / 2 - 16
            preferredHighlightEnd: width / 2 + 16
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 250 

            delegate: Item {
                width: 32
                height: 32
                
                property bool isActive: index === listView.currentIndex
                property bool isOccupied: {
                    if (!Hyprland.workspaces) return false;
                    var wsId = index + 1;
                    var vals = Hyprland.workspaces.values;
                    for (var i = 0; i < vals.length; i++) {
                        if (vals[i] && vals[i].id === wsId) return true;
                    }
                    return false;
                }

                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Hyprland.dispatch("workspace " + (index + 1));
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: index + 1
                    font.family: Appearance.fontFamily || "sans-serif"
                    font.pixelSize: 12
                    font.bold: isActive

                    
                    scale: isActive ? 1.25 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }

                    
                    Behavior on color { ColorAnimation { duration: 200 } }

                    color: {
                        if (isActive) {
                            return Appearance.colors.colPrimary; 
                        } else if (isOccupied) {
                            return Appearance.colors.colOnLayer0; 
                        } else {
                            return ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4); 
                        }
                    }
                }
            }
        }
    }
}
