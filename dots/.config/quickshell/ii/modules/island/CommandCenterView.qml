import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter
import qs.modules.waffle.actionCenter.wifi
import qs.modules.waffle.actionCenter.volumeControl

Item {
    id: root
    implicitWidth: 420
    implicitHeight: header.height + stack.implicitHeight + 44
    
    property var islandWindow: null

    component ToggleButton : Rectangle {
        id: btn
        property string title: ""
        property string subtext: ""
        property string iconSource: ""
        property bool active: false
        property var onClickedCallback: null
        property var onRightClickedCallback: null
        
        Layout.fillWidth: true
        height: 52
        radius: 16
        color: active ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    if (onRightClickedCallback) onRightClickedCallback();
                } else {
                    if (onClickedCallback) onClickedCallback();
                }
            }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: btn.active ? Qt.rgba(0,0,0,0.1) : Qt.rgba(255,255,255,0.08)
                
                Image {
                    id: btnIcon
                    source: btn.iconSource
                    anchors.fill: parent
                    anchors.margins: 8
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: btnIcon
                    source: btnIcon
                    color: {
                        if (btn.active) {
                            if (Appearance.colors && Appearance.colors.colOnPrimary)
                                return Appearance.colors.colOnPrimary;
                            var p = Appearance.colors.colPrimary;
                            var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
                            return l > 0.5 ? "#1a120b" : "#ffffff";
                        }
                        return Appearance.colors.colOnLayer0;
                    }
                }
            }
            
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                
                Text {
                    text: btn.title
                    color: {
                        if (btn.active) {
                            if (Appearance.colors && Appearance.colors.colOnPrimary)
                                return Appearance.colors.colOnPrimary;
                            var p = Appearance.colors.colPrimary;
                            var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
                            return l > 0.5 ? "#1a120b" : "#ffffff";
                        }
                        return Appearance.colors.colOnLayer0;
                    }
                    font.family: Appearance.fontFamily || "sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    text: btn.subtext
                    color: {
                        if (btn.active) {
                            if (Appearance.colors && Appearance.colors.colOnPrimary)
                                return Qt.rgba(Appearance.colors.colOnPrimary.r, Appearance.colors.colOnPrimary.g, Appearance.colors.colOnPrimary.b, 0.7);
                            var p = Appearance.colors.colPrimary;
                            var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
                            return l > 0.5 ? "rgba(26, 18, 11, 0.7)" : "rgba(255, 255, 255, 0.7)";
                        }
                        return Appearance.colors.colOnSurfaceVariant;
                    }
                    font.family: Appearance.fontFamily || "sans-serif"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    component CustomSlider : Rectangle {
        id: slider
        property real value: 0.5 
        property string iconSource: ""
        property var onValueChangedCallback: null
        
        Layout.fillWidth: true
        height: 36
        radius: 18
        color: Appearance.colors.colLayer1
        
        Rectangle {
            id: fillArea
            width: Math.max(slider.height, slider.width * slider.value)
            height: parent.height
            radius: parent.radius
            color: Appearance.colors.colPrimary

            Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
        
        Rectangle {
            id: iconCircle
            width: 28
            height: 28
            radius: 14
            color: "transparent"
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            
            Image {
                id: sIcon
                source: slider.iconSource
                anchors.fill: parent
                anchors.margins: 6
                fillMode: Image.PreserveAspectFit
                visible: false
            }
            ColorOverlay {
                anchors.fill: sIcon
                source: sIcon
                color: {
                    if (slider.value > 0.08) {
                        if (Appearance.colors && Appearance.colors.colOnPrimary)
                            return Appearance.colors.colOnPrimary;
                        var p = Appearance.colors.colPrimary;
                        var l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
                        return l > 0.5 ? "#1a120b" : "#ffffff";
                    }
                    return Appearance.colors.colOnLayer0;
                }
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            
            function updateValue(mouse) {
                var val = Math.max(0, Math.min(1, mouse.x / slider.width));
                if (onValueChangedCallback) onValueChangedCallback(val);
            }
            
            onPressed: updateValue(mouse)
            onPositionChanged: updateValue(mouse)
            onWheel: (event) => {
                var step = event.angleDelta.y > 0 ? 0.05 : -0.05;
                var newVal = Math.max(0, Math.min(1, slider.value + step));
                if (onValueChangedCallback) onValueChangedCallback(newVal);
            }
        }
    }

    RowLayout {
        id: header
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 16
            leftMargin: 24
            rightMargin: 24
        }
        height: 40
        spacing: 12
        
        Rectangle {
            id: backButton
            width: 40
            height: 40
            radius: 20
            color: Appearance.colors.colLayer1
            
            Text {
                anchors.centerIn: parent
                text: "←"
                color: Appearance.colors.colOnLayer0
                font.pixelSize: 20
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (stack.depth > 1) {
                        stack.pop();
                    } else if (root.islandWindow) {
                        root.islandWindow.controlCenterOpen = false
                    }
                }
            }
        }
        
        Text {
            text: stack.depth > 1 ? stack.currentItem.title : "Control Center"
            color: Appearance.colors.colOnLayer0
            font.family: Appearance.fontFamily || "sans-serif"
            font.pixelSize: 22
            font.bold: true
        }
    }

    StackView {
        id: stack
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            topMargin: 12
            leftMargin: 24
            rightMargin: 24
        }
        
        implicitHeight: currentItem ? currentItem.implicitHeight : 0
        height: implicitHeight
        initialItem: mainView
    }

    Component {
        id: wifiView
        WifiControl {
            readonly property string title: "Wi-Fi"
            width: stack.width
            implicitHeight: 450 
            height: implicitHeight
        }
    }

    Component {
        id: audioView
        VolumeControl {
            readonly property string title: "Audio"
            width: stack.width
            implicitHeight: 400 
            height: implicitHeight
        }
    }

    Component {
        id: mainView
        ColumnLayout {
            spacing: 12
            readonly property string title: "Control Center"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                ToggleButton {
                    title: "Wi-Fi"
                    subtext: Network.wifiEnabled ? (Network.wifiStatus === "connected" ? Network.networkName : Network.wifiStatus) : "Disabled"
                    active: Network.wifiEnabled
                    iconSource: "../../assets/icons/fluent/wifi-4-filled.svg"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 40
                    onClickedCallback: () => Network.toggleWifi()
                    onRightClickedCallback: () => stack.push(wifiView)
                }
                
                ToggleButton {
                    title: "Audio"
                    subtext: Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : "No device"
                    active: !Audio.sink?.audio?.muted
                    iconSource: "../../assets/icons/fluent/speaker-2-filled.svg"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 60
                    onClickedCallback: () => Audio.toggleMute()
                    onRightClickedCallback: () => stack.push(audioView)
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
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                        }
                    }
                }
                
                ToggleButton {
                    title: "Performance"
                    subtext: PowerProfiles.profile === PowerProfile.Performance ? "Performance" : (PowerProfiles.profile === PowerProfile.PowerSaver ? "Power Saver" : "Balanced")
                    active: PowerProfiles.profile === PowerProfile.Performance
                    iconSource: "../../assets/icons/fluent/fire-filled.svg"
                    onClickedCallback: () => {
                        if (PowerProfiles.hasPerformanceProfile) {
                            switch(PowerProfiles.profile) {
                                case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break;
                                case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break;
                                case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver; break;
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

            CustomSlider {
                iconSource: "../../assets/icons/fluent/speaker-2-filled.svg"
                value: Audio.sink?.audio?.volume ?? 0
                onValueChangedCallback: function(val) {
                    if (Audio.sink?.audio) Audio.sink.audio.volume = val;
                }
            }

            CustomSlider {
                iconSource: "../../assets/icons/fluent/weather-sunny-filled.svg"
                value: Brightness.getMonitorForScreen(root.islandWindow?.screen)?.brightness ?? 0.5
                onValueChangedCallback: function(val) {
                    Brightness.getMonitorForScreen(root.islandWindow?.screen)?.setBrightness(val);
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 140
                radius: 20
                color: Appearance.colors.colLayer1
                clip: true
                
                Timer {
                    running: MprisController.activePlayer?.isPlaying ?? false
                    interval: 1000
                    repeat: true
                    onTriggered: MprisController.activePlayer?.positionChanged()
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8
                    
                    RowLayout {
                        spacing: 6
                        
                        Item {
                            width: 12
                            height: 12
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            
                            Image {
                                id: speakerMiniIcon
                                source: "../../assets/icons/fluent/speaker-2-filled.svg"
                                anchors.fill: parent
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: parent
                                source: speakerMiniIcon
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                        
                        Text {
                            text: MprisController.activePlayer?.trackTitle ?? "No music"
                            color: Appearance.colors.colOnLayer0
                            font.family: Appearance.fontFamily || "sans-serif"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                
                                Text {
                                    width: parent.width
                                    text: MprisController.activePlayer?.trackTitle ?? "No music"
                                    color: Appearance.colors.colOnLayer0
                                    font.family: Appearance.fontFamily || "sans-serif"
                                    font.pixelSize: 18
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: MprisController.activePlayer?.trackArtist ?? "Unknown artist"
                                    color: Appearance.colors.colOnSurfaceVariant
                                    font.family: Appearance.fontFamily || "sans-serif"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            color: Appearance.colors.colLayer0
                            
                            Text {
                                anchors.centerIn: parent
                                text: MprisController.activePlayer?.isPlaying ? "‖" : "▶"
                                color: Appearance.colors.colOnLayer0
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MprisController.activePlayer?.togglePlaying()
                            }
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Text {
                            text: "⏮"
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MprisController.activePlayer?.previous()
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Appearance.colors.colLayer0
                            
                            Rectangle {
                                width: {
                                    if (MprisController.activePlayer && MprisController.activePlayer.length > 0) {
                                        var pos = MprisController.activePlayer.position || 0;
                                        var len = MprisController.activePlayer.length;
                                        return (pos / len) * parent.width;
                                    }
                                    return 0;
                                }
                                height: parent.height
                                radius: parent.radius
                                color: Appearance.colors.colOnLayer0
                                
                                Behavior on width {
                                    NumberAnimation { duration: 1000; easing.type: Easing.Linear }
                                }
                            }
                        }
                        
                        Text {
                            text: "⏭"
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MprisController.activePlayer?.next()
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "Notifications"
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: Appearance.fontFamily || "sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: "Clear all"
                        color: Appearance.colors.colPrimary
                        font.family: Appearance.fontFamily || "sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.discardAllNotifications()
                        }
                    }
                }
                
                ScrollView {
                    id: notifScroll
                    Layout.fillWidth: true
                    clip: true
                    implicitHeight: Math.min(220, notifList.implicitHeight)
                    
                    ColumnLayout {
                        id: notifList
                        width: notifScroll.width
                        spacing: 8
                        
                        Repeater {
                            id: notifRepeater
                            // UPGRADE: Fallback chain checks history list before falling back to short-lived popupList
                            model: Notifications.notificationList || Notifications.notifications || Notifications.popupList
                            
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 64
                                radius: 16
                                color: Appearance.colors.colLayer1
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12
                                    
                                    Image {
                                        id: notifIcon
                                        source: modelData.appIcon || modelData.image || "image://icon/dialog-information"
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        fillMode: Image.PreserveAspectFit
                                        visible: modelData.appIcon || modelData.image
                                    }
                                    
                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            text: modelData.summary || ""
                                            color: Appearance.colors.colOnLayer0
                                            font.family: Appearance.fontFamily || "sans-serif"
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Text {
                                            text: modelData.body || ""
                                            color: Appearance.colors.colOnSurfaceVariant
                                            font.family: Appearance.fontFamily || "sans-serif"
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    
                                    Text {
                                        text: "✕"
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: 12
                                        font.bold: true
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (typeof modelData.dismiss === "function") {
                                                    modelData.dismiss();
                                                } else if (typeof Notifications.dismissNotification === "function") {
                                                    Notifications.dismissNotification(modelData.notificationId);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            visible: notifRepeater.count === 0
                            text: "All clear"
                            color: Appearance.colors.colOnSurfaceVariant
                            font.family: Appearance.fontFamily || "sans-serif"
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignCenter
                            Layout.topMargin: 16
                            Layout.bottomMargin: 16
                        }
                    }
                }
            }
        }
    }
}
