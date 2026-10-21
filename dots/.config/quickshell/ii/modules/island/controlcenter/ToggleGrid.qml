import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.services
import qs.modules.common.widgets
import qs.modules.common
import qs.modules.waffle.looks

ColumnLayout {
    id: root
    spacing: 10
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ToggleButton {
            title: "Wi-Fi"
            subtext: Network.wifiEnabled ? (Network.wifiStatus === "connected" ? Network.networkName : Network.wifiStatus) : "Disabled"
            active: Network.wifiEnabled
            iconSource: "../../../assets/icons/fluent/wifi-4-filled.svg"
            Layout.fillWidth: true
            onClickedCallback: () => Network.toggleWifi()
            onRightClickedCallback: () => stackViewRef.push(wifiViewRef)
        }

        ToggleButton {
            title: "Audio"
            subtext: Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : "No device"
            active: !Audio.sink?.audio?.muted
            iconSource: "../../../assets/icons/fluent/speaker-2-filled.svg"
            Layout.fillWidth: true
            onClickedCallback: () => Audio.toggleMute()
            onRightClickedCallback: () => stackViewRef.push(audioViewRef)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ToggleButton {
            title: "Bluetooth"
            subtext: BluetoothStatus.enabled ? "On" : "Off"
            active: BluetoothStatus.enabled
            iconSource: WIcons.pathForName(WIcons.bluetoothIcon)
            onClickedCallback: () => {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
            }
        }

        ToggleButton {
            title: "Performance"
            subtext: PowerProfiles.profile === PowerProfile.Performance ? "Performance" : (PowerProfiles.profile === PowerProfile.PowerSaver ? "Power Saver" : "Balanced")
            active: PowerProfiles.profile === PowerProfile.Performance
            iconSource: "../../../assets/icons/fluent/fire-filled.svg"
            onClickedCallback: () => {
                if (PowerProfiles.hasPerformanceProfile) {
                    switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break
                        case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break
                        case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver; break
                    }
                } else {
                    PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ToggleButton {
            title: "Peace"
            subtext: Notifications.silent ? "On" : "Off"
            active: Notifications.silent
            iconSource: WIcons.pathForName(WIcons.notificationsIcon)
            onClickedCallback: () => Notifications.silent = !Notifications.silent
        }

        ToggleButton {
            title: "Night Light"
            subtext: Hyprsunset.temperatureActive ? "On" : "Off"
            active: Hyprsunset.temperatureActive
            iconSource: WIcons.pathForName(WIcons.nightLightIcon)
            onClickedCallback: () => Hyprsunset.toggleTemperature()
        }
    }

    property var stackViewRef
    property var wifiViewRef
    property var audioViewRef
}