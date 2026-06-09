import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root
    property bool output: true
    property string title: "Audio"

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        StyledFlickable {
            id: flickable
            Layout.fillHeight: true
            Layout.fillWidth: true

            contentHeight: contentLayout.implicitHeight
            contentWidth: width
            clip: true

            AudioChoices {
                id: contentLayout
                width: flickable.width
            }
        }

        RowLayout {
            Layout.fillWidth: true
            WTextButton {
                text: Translation.tr("More volume settings")
                onClicked: {
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "sidebarLeft", "toggle"]);
                    Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
                }
            }
        }
    }

    component AudioChoices: ColumnLayout {
        spacing: 4

        SectionText {
            text: root.output ? Translation.tr("Output device") : Translation.tr("Input device")
        }

        Repeater {
            model: ScriptModel {
                values: root.output ? Audio.outputDevices : Audio.inputDevices
            }
            delegate: WChoiceButton {
                required property var modelData
                icon.name: WIcons.audioDeviceIcon(modelData)
                text: Audio.friendlyDeviceName(modelData)
                checked: (root.output ? Audio.sink : Audio.source) === modelData
                onClicked: {
                    if (root.output) Audio.setDefaultSink(modelData);
                    else Audio.setDefaultSource(modelData);
                }
            }
        }

        WPanelSeparator {
            visible: EasyEffects.available && root.output
            color: Looks.colors.bg2Hover
        }

        SectionText {
            visible: EasyEffects.available && root.output
            text: Translation.tr("Sound effects")
        }

        WChoiceButton {
            visible: EasyEffects.available && root.output
            text: Translation.tr("Off")
            checked: !EasyEffects.active
            onClicked: EasyEffects.disable()
        }

        WChoiceButton {
            visible: EasyEffects.available && root.output
            text: "EasyEffects"
            checked: EasyEffects.active
            onClicked: EasyEffects.enable()
        }

        WPanelSeparator {
            color: Looks.colors.bg2Hover
        }

        SectionText {
            visible: EasyEffects.available
            text: Translation.tr("Volume mixer")
        }

        VolumeEntry {
            node: root.output ? Audio.sink : Audio.source
            icon: root.output ? "speaker" : "mic-on"
            monochrome: true
        }

        Repeater {
            model: ScriptModel {
                values: root.output ? Audio.outputAppNodes : Audio.inputAppNodes
            }
            delegate: VolumeEntry {
                required property var modelData
                node: modelData
            }
        }
    }
}
