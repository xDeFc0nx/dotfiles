import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root
    spacing: 10
    Layout.fillWidth: true

    property var islandWindow: null

    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(islandWindow?.screen)
    readonly property real brightnessValue: brightnessMonitor?.brightness ?? 0.5

    CustomSlider {
        iconSource: "../../../assets/icons/fluent/speaker-2-filled.svg"
        value: Audio.sink?.audio?.volume ?? 0
        onValueChangedCallback: function(val) {
            if (Audio.sink?.audio) Audio.sink.audio.volume = val
        }
    }

    CustomSlider {
        iconSource: "../../../assets/icons/fluent/weather-sunny-filled.svg"
        value: brightnessValue
        onValueChangedCallback: function(val) {
            brightnessMonitor?.setBrightness(val)
        }
    }
}