// modules/island/services/IslandStateManager.qml
pragma Singleton
import QtQuick
import qs.services

// This service centralizes the state logic previously cluttered in IslandFamily.qml
// It acts as the "Brain" for the Island theme.

QtObject {
    id: root

    // --- State Properties ---
    property bool isExpanded: false
    property bool showingVolume: false
    property bool showingBrightness: false
    property bool showingNotification: false
    property bool isFlashing: false
    property bool launcherOpen: false

    // --- Notifications State ---
    property var activeNotification: null
    property color flashColor: "#ffffff"

    // --- Timers ---
    property Timer volumeCloseTimer: Timer {
        interval: 1500
        onTriggered: root.showingVolume = false
    }

    property Timer brightnessCloseTimer: Timer {
        interval: 1500
        onTriggered: root.showingBrightness = false
    }

    property Timer notificationCloseTimer: Timer {
        interval: 5000
        onTriggered: {
            root.isExpanded = false
            resetStateTimer.start()
        }
    }

    property Timer resetStateTimer: Timer {
        interval: 300
        onTriggered: {
            root.showingNotification = false
            root.activeNotification = null
        }
    }

    property Timer hoverDebounceTimer: Timer {
        interval: 300
        onTriggered: root.isExpanded = false
    }

    // --- Actions ---
    function triggerVolume(delta) {
        if (!Audio.sink?.audio) return
        
        const newVol = Math.max(0, Math.min(1, Audio.sink.audio.volume + (delta > 0 ? 0.02 : -0.02)))
        Audio.sink.audio.volume = newVol
        if (newVol > 0 && Audio.sink.audio.muted) Audio.sink.audio.muted = false
        
        root.showingBrightness = false
        root.showingVolume = true
        root.volumeCloseTimer.restart()
    }

    function triggerBrightness(monitor, delta) {
        if (!monitor) return
        
        const newBright = Math.max(0, Math.min(1, monitor.brightness + (delta > 0 ? 0.05 : -0.05)))
        monitor.setBrightness(newBright)
        
        root.showingVolume = false
        root.showingBrightness = true
        root.brightnessCloseTimer.restart()
    }

    function postNotification(title, body, icon, id, notificationData) {
        notificationCloseTimer.stop()
        resetStateTimer.stop()
        
        activeNotification = { title, body, icon, id }
        
        // Logic for flash color logic can be moved here or kept in view
        isExpanded = false
        isFlashing = true
    }
}
