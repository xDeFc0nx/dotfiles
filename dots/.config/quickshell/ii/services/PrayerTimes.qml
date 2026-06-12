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

    property var currentTime: new Date()

    property Timer tickTimer: Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    readonly property var nextPrayerData: {
        var now = root.currentTime; 

        if (!timings || Object.keys(timings).length === 0) return { name: "Loading...", time: "--:--", countdown: "--" };

        var currentMinutes = now.getHours() * 60 + now.getMinutes();
        
        var prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
        var nextP = "";
        var nextT = "";
        var minDiff = 24 * 60;

        for (var i = 0; i < prayers.length; i++) {
            var p = prayers[i];
            var timeStr = timings[p];
            if (!timeStr) continue;

            var parts = timeStr.split(":");
            var pMinutes = parseInt(parts[0]) * 60 + parseInt(parts[1]);
            
            var diff = pMinutes - currentMinutes;
            if (diff > 0 && diff < minDiff) {
                minDiff = diff;
                nextP = p;
                nextT = timeStr;
            }
        }

        if (nextP === "") {
            nextP = "Fajr";
            nextT = timings["Fajr"] || "--:--";
            if (nextT !== "--:--") {
                var fParts = nextT.split(":");
                var fMinutes = parseInt(fParts[0]) * 60 + parseInt(fParts[1]);
                minDiff = (24 * 60 - currentMinutes) + fMinutes;
            }
        }

        var h = Math.floor(minDiff / 60);
        var m = minDiff % 60;
        var countdown = h > 0 ? (h + "h " + m + "m") : (m + "m");

        return { name: nextP, time: nextT, countdown: countdown };
    }

    readonly property string nextPrayerStr: nextPrayerData.name + " " + nextPrayerData.time
    
    property Timer updateTimer: Timer {
        interval: 3600000
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
