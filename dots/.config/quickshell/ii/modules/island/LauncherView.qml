import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import "../ii/overview"

Item {
    id: launcherView

    required property var islandWindow

    property int selectedIndex: 0

    implicitHeight: mainLayout.implicitHeight + 24
    implicitWidth: 420

    Connections {
        target: LauncherSearch
        function onQueryChanged() {
            if (searchInput.text !== LauncherSearch.query) {
                searchInput.text = LauncherSearch.query;
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
            if (typeof islandFamily !== "undefined" && !islandFamily.dontAutoCancelSearch) {
                searchInput.text = "";
                LauncherSearch.query = "";
            }
            selectedIndex = 0;
        } else {
            if (typeof islandFamily !== "undefined") {
                islandFamily.dontAutoCancelSearch = false;
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "search"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Appearance.colors.colSubtext || "#888888"
                Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 30
                Layout.preferredHeight: 30
                horizontalAlignment: TextInput.AlignLeft
                verticalAlignment: TextInput.AlignVCenter
                color: Appearance.colors.colOnLayer0 || "#ffffff"
                font.family: Appearance.fontFamily || "sans-serif"
                font.pixelSize: 16

                Text {
                    text: "Search..."
                    color: Appearance.colors.colSubtext || "#666666"
                    font: parent.font
                    visible: parent.text === ""
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                onTextChanged: {
                    if (LauncherSearch.query !== text) {
                        LauncherSearch.query = text;
                    }
                    launcherView.selectedIndex = 0;
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down) {
                        if (resultsList.count > 0) {
                            launcherView.selectedIndex = (launcherView.selectedIndex + 1) % resultsList.count;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (resultsList.count > 0) {
                            launcherView.selectedIndex = (launcherView.selectedIndex - 1 + resultsList.count) % resultsList.count;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return) {
                        if (resultsList.count > 0 && launcherView.selectedIndex >= 0 && launcherView.selectedIndex < resultsList.count) {
                            var item = LauncherSearch.results[launcherView.selectedIndex];
                            if (item && item.execute) {
                                item.execute();
                                GlobalStates.overviewOpen = false;
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        if (resultsList.count > 0 && launcherView.selectedIndex >= 0 && launcherView.selectedIndex < resultsList.count) {
                            var item = LauncherSearch.results[launcherView.selectedIndex];
                            if (item) {
                                searchInput.text = item.name;
                                LauncherSearch.query = item.name;
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                    }
                }
            }
        }

        Rectangle {
            id: separator
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colBorder || "#333333"
            opacity: 0.4
            visible: resultsList.count > 0
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            implicitHeight: resultsList.count > 0 ? Math.min(320, resultsList.contentHeight) : 0
            visible: resultsList.count > 0
            model: LauncherSearch.results
            currentIndex: launcherView.selectedIndex
            clip: true
            spacing: 6

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutQuad }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutQuad }
            }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
            }

            delegate: SearchItem {
                id: searchItem
                required property var modelData
                required property int index

                width: resultsList.width
                entry: modelData
                query: StringUtils.cleanOnePrefix(searchInput.text, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])
                focus: index === launcherView.selectedIndex
            }
        }
    }
}
