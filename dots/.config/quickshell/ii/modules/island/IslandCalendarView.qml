import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.calendar

Item {
    id: root

    property var islandWindow: null

    readonly property int padding: 12

    implicitWidth: calendarWidget.width + padding * 2
    implicitHeight: calendarWidget.implicitHeight + padding * 2

    focus: islandWindow ? islandWindow.calendarOpen : false

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => root.forceActiveFocus());
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (islandWindow)
                islandWindow.calendarOpen = false;
            event.accepted = true;
        } else if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            calendarWidget.monthShift += (event.key === Qt.Key_PageDown) ? 1 : -1;
            event.accepted = true;
        }
    }

    CalendarWidget {
        id: calendarWidget
        anchors.centerIn: parent
    }
}
