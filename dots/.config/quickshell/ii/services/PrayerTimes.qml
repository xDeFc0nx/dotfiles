pragma Singleton
import QtQuick
import Quickshell
import QtPositioning
import qs.services

QtObject {
    id: root

    property var timings: ({})
    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })
    
    property Timer updateTimer: Timer {
        interval: 3600000 // 1 hour
        running: true
        repeat: true
        onTriggered: fetchPrayerTimes()
    }

    property PositionSource positionSource: PositionSource {
        updateInterval: 3600000 
        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.lon = position.coordinate.longitude;
                root.location.valid = true;
                fetchPrayerTimes();
                positionSource.stop();
            }
        }
    }

    function fetchPrayerTimes() {
        var url = "http://api.aladhan.com/v1/timings";
        if (root.location.valid) {
            url += `?latitude=${root.location.lat}&longitude=${root.location.lon}&method=3`;
        } else {
            url += "?city=Skopje&country=North Macedonia&method=3";
        }
        
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                root.timings = response.data.timings;
                console.log("Prayer times loaded.");
            }
        }
        xhr.send();
    }

    Component.onCompleted: {
        root.positionSource.start();
        fetchPrayerTimes();
    }
}
