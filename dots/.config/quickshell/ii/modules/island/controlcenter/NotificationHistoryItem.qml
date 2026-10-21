import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import "AppColorHelper.js" as AppColorHelper

Rectangle {
    id: notifItem
    required property var modelData

    Layout.fillWidth: true
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1
    implicitHeight: contentColumn.implicitHeight + 16

    readonly property bool darkmode: Appearance.m3colors && Appearance.m3colors.darkmode
    property color accentColor: AppColorHelper.accentStripeColor(modelData.appName, darkmode)
    property color iconBgColor: AppColorHelper.iconBackgroundColor(modelData.appName, darkmode)
    property color appNameColor: AppColorHelper.appNameColor(modelData.appName, darkmode)

    function goToApp() {
        // Helper: clean app name (strip channel suffixes like " (#news-approval, staff)")
        function cleanAppName(name) {
            if (!name) return ""
            return name.replace(/\s*\(#.*\)\s*$/, "").trim()
        }

        const cleanName = cleanAppName(modelData.appName)

        // Step 1: If we have the raw notification object (live notification), try to invoke
        // its actions directly. The raw actions have .invoke() methods that deep-link
        // (e.g. Discord opens the specific channel/message).
        if (modelData.notification && modelData.notification.actions && modelData.notification.actions.length > 0) {
            const rawActions = modelData.notification.actions

            // Priority 1: "default" action identifier
            let actionToInvoke = rawActions.find(a => a.identifier === "default")

            // Priority 2: action whose text/identifier suggests opening/viewing/replying
            if (!actionToInvoke) {
                const openKeywords = ["open", "view", "show", "reply", "go to", "go to channel", "go to message"]
                actionToInvoke = rawActions.find(a =>
                    openKeywords.some(kw =>
                        (a.text && a.text.toLowerCase().includes(kw)) ||
                        (a.identifier && a.identifier.toLowerCase().includes(kw))
                    )
                )
            }

            // Priority 3: first available action
            if (!actionToInvoke) {
                actionToInvoke = rawActions[0]
            }

            if (actionToInvoke && typeof actionToInvoke.invoke === "function") {
                console.log("[NotificationHistoryItem] Invoking notification action:", actionToInvoke.identifier, actionToInvoke.text)
                actionToInvoke.invoke()
                return
            }
        }

        // Step 2: Fallback to service's attemptInvokeAction (works for tracked notifications)
        // This handles the case where notification is tracked but we didn't catch it above
        if (modelData.actions && modelData.actions.length > 0) {
            var defaultAction = modelData.actions.find(a => a.identifier === "default")
            if (defaultAction) {
                Notifications.attemptInvokeAction(modelData.notificationId, "default")
                return
            }
        }

        // Step 3: If live notification with desktopEntry/appId, find exact matching toplevel
        if (modelData.notification) {
            const desktopEntry = modelData.notification.desktopEntry
            const appId = modelData.notification.appId
            if (desktopEntry || appId) {
                for (const toplevel of ToplevelManager.toplevels.values) {
                    const match = (appId && toplevel.appId.toLowerCase() === appId.toLowerCase()) ||
                                  (desktopEntry && toplevel.appId.toLowerCase() === desktopEntry.toLowerCase())
                    if (match) {
                        toplevel.activate()
                        return
                    }
                }
            }
        }

        // Step 4: Find toplevel whose appId contains/equals cleanName (case-insensitive)
        if (cleanName) {
            for (const toplevel of ToplevelManager.toplevels.values) {
                if (toplevel.appId.toLowerCase().includes(cleanName.toLowerCase()) ||
                    cleanName.toLowerCase().includes(toplevel.appId.toLowerCase())) {
                    toplevel.activate()
                    return
                }
            }
        }

        // Step 5: Launch via desktop entry
        // Try desktopEntry from live notification first
        if (modelData.notification?.desktopEntry) {
            const entry = DesktopEntries.byId(modelData.notification.desktopEntry)
            if (entry) {
                entry.execute()
                return
            }
        }
        // Try heuristic lookup with clean app name
        if (cleanName) {
            const heuristicEntry = DesktopEntries.heuristicLookup(cleanName)
            if (heuristicEntry) {
                heuristicEntry.execute()
                return
            }
            // Last resort: AppSearch fuzzy query
            const searchResults = AppSearch.fuzzyQuery(cleanName)
            if (searchResults.length > 0) {
                searchResults[0].execute()
                return
            }
        }

        // Step 6: Nothing worked
        console.log("[NotificationHistoryItem] Could not find or launch app for:", modelData.appName)
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                id: accentStripe
                width: 3
                Layout.alignment: Qt.AlignTop
                Layout.fillHeight: true
                radius: 1.5
                color: accentColor
                visible: modelData.appName && modelData.appName.length > 0
            }

            NotificationAppIcon {
                id: historyNotifIcon
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignTop
                appIcon: modelData.appIcon
                image: modelData.image
                summary: modelData.summary
                urgency: modelData.urgency === "critical" ? NotificationUrgency.Critical : NotificationUrgency.Normal
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: modelData.appName || ""
                        color: appNameColor
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        font.variableAxes: Appearance.font.variableAxes.main
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: NotificationUtils.getFriendlyNotifTimeString(modelData.time)
                        color: Appearance.colors.colSubtext
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.variableAxes: Appearance.font.variableAxes.main
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    }
                }

                StyledText {
                    text: modelData.summary || ""
                    color: Appearance.colors.colOnLayer0
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.bold: true
                    font.variableAxes: Appearance.font.variableAxes.main
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 1
                }

                StyledText {
                    text: modelData.body || ""
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.variableAxes: Appearance.font.variableAxes.main
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
            }

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignTop

                RippleButton {
                    id: viewButton
                    buttonText: ""
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    releaseAction: () => {
                        goToApp()
                    }

                    contentItem: MaterialSymbol {
                        text: "open_in_new"
                        color: Appearance.colors.colOnSurfaceVariant
                        iconSize: Appearance.font.pixelSize.small
                    }

                    ToolTip.visible: true
                    ToolTip.text: "View"
                    ToolTip.delay: 500
                }

                RippleButton {
                    id: dismissButton
                    buttonText: ""
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    releaseAction: () => Notifications.discardNotification(modelData.notificationId)

                    contentItem: MaterialSymbol {
                        text: "close"
                        color: Appearance.colors.colOnSurfaceVariant
                        iconSize: Appearance.font.pixelSize.small
                    }

                    ToolTip.visible: true
                    ToolTip.text: "Clear"
                    ToolTip.delay: 500
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                goToApp()
            }
        }
    }
}