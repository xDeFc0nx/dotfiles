pragma Singleton
import QtQuick

QtObject {
    property var sizes: {
        "rest": Qt.size(130, 40),
        "hover": Qt.size(450, 60), 
        "volume": Qt.size(200, 40),
        "brightness": Qt.size(200, 40),
        "notification": Qt.size(350, 80),
        "prayer": Qt.size(280, 60),
        "controlCenter": Qt.size(500, 500),
        "launcher": Qt.size(500, 400)
    }
}
