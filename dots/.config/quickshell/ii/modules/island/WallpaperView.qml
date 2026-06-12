pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggleWallpaperSelector();
        }

        function random(): void {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: {
            root.toggleWallpaperSelector();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    function toggleWallpaperSelector() {
        if (Config.options.wallpaperSelector.useSystemFileDialog) {
            Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode);
            return;
        }
        GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 12

        // --- HEADER ---
        RowLayout {
            Layout.fillWidth: true
            height: 32

            Text {
                text: "Wallpaper"
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 18
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: {
                    var pathStr = Wallpapers.effectiveDirectory.toString();
                    var parts = pathStr.split("/");
                    return parts[parts.length - 1] || "Wallpapers";
                }
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 11
                font.bold: true
                opacity: 0.8
            }
        }

        // --- GRID ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                
                // Configured to fit exactly 3 columns across the 384px usable layout span
                cellWidth: 128
                cellHeight: 80
                
                cacheBuffer: 500
                
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                model: Wallpapers.folderModel

                delegate: Item {
                    id: delegateRoot
                    width: grid.cellWidth
                    height: grid.cellHeight

                    required property var modelData
                    required property string filePath
                    required property string fileName
                    required property bool fileIsDir

                    readonly property string filePathStr: (typeof modelData !== "undefined" && modelData.filePath) ? modelData.filePath : (filePath ? filePath : "")
                    readonly property string fileNameStr: (typeof modelData !== "undefined" && modelData.fileName) ? modelData.fileName : (fileName ? fileName : "")
                    readonly property bool isDirectory: (typeof modelData !== "undefined" && modelData.fileIsDir !== undefined) ? modelData.fileIsDir : (fileIsDir ? fileIsDir : false)
                    readonly property bool isActive: filePathStr === Config.options.background.wallpaperPath

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 12
                        clip: true

                        color: isDirectory ? Appearance.colors.colLayer1 : "transparent"
                        border.width: isActive ? 2 : 1
                        border.color: isActive ? Appearance.colors.colPrimary : (itemMouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent")

                        // Directory Representation
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            visible: isDirectory
                            spacing: 4

                            Text {
                                text: "📁"
                                font.pixelSize: 22
                                Layout.alignment: Qt.AlignCenter
                            }

                            Text {
                                text: fileNameStr
                                color: Appearance.colors.colOnLayer0
                                font.family: Appearance.fontFamily || "sans-serif"
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Wallpaper Thumbnail Representation
                        Image {
                            anchors.fill: parent
                            visible: !isDirectory
                            source: filePathStr ? "file://" + filePathStr : ""
                            fillMode: Image.PreserveAspectCrop
                            
                            asynchronous: true
                            cache: true
                            
                            sourceSize.width: 128
                            sourceSize.height: 80

                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: itemMouseArea.containsMouse ? 0.25 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                if (isDirectory) {
                                    Wallpapers.setDirectory(filePathStr);
                                } else {
                                    Wallpapers.select(filePathStr, Appearance.m3colors.darkmode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- FOOTER ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            height: 36

            Rectangle {
                height: 36
                radius: 18
                color: Appearance.colors.colLayer1
                Layout.preferredWidth: 140

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "◀"
                            font.pixelSize: 11
                            color: Appearance.colors.colOnLayer0
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.navigateBack()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "▲"
                            font.pixelSize: 11
                            color: Appearance.colors.colOnLayer0
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.navigateUp()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "▶"
                            font.pixelSize: 11
                            color: Appearance.colors.colOnLayer0
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.navigateForward()
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Appearance.colors.colLayer1

                Text {
                    anchors.centerIn: parent
                    text: "🎲"
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpapers.randomFromCurrentFolder(Appearance.m3colors.darkmode)
                }
            }
        }
    }
}
