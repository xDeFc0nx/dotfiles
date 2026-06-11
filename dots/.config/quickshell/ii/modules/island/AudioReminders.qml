pragma Singleton
import QtQuick
import Quickshell
import qs.services

QtObject {
    id: root

    
    
    property string audioDirectory: Quickshell.configDir + "/assets/audio"

    
    property string playerExecutable: "mpv"
    property var playerArgs: ["--no-video"] 

    
    property string weekdayPlayTime: "08:00"
    property string sabahAdhkarTime: "07:00" 
    property string masaAdhkarTime: "17:00"  

    
    property var duaTimes: ["12:00", "18:00", "21:00"]
    

    
    property string lastPlayedPrayer: ""
    property int lastPlayedPrayerDay: -1

    property int lastPlayedWeekdayDay: -1
    property int lastPlayedSabahDay: -1
    property int lastPlayedMasaDay: -1

    property string lastPlayedDuaTime: ""
    property int lastPlayedDuaDay: -1

    
    property Timer schedulerTimer: Timer {
        interval: 60000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkSchedules()
    }

    function playAudio(fileName) {
        var absolutePath = root.audioDirectory + "/" + fileName;
        console.log("[AudioReminders] Triggering playback of: " + absolutePath);
        
        
        Quickshell.execDetached([root.playerExecutable].concat(root.playerArgs).concat([absolutePath]));
    }

    function checkSchedules() {
        var now = new Date();
        var currentMinStr = Qt.formatTime(now, "HH:mm");
        var currentDay = now.getDate();
        var dayOfWeek = now.getDay(); 

        
        var mainPrayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
        for (var i = 0; i < mainPrayers.length; i++) {
            var p = mainPrayers[i];
            var pTime = PrayerTimes.timings[p]; 
            
            if (pTime) {
                pTime = pTime.trim();
                if (currentMinStr === pTime) {
                    if (root.lastPlayedPrayer !== p || root.lastPlayedPrayerDay !== currentDay) {
                        root.lastPlayedPrayer = p;
                        root.lastPlayedPrayerDay = currentDay;

                        var pFile = "";
                        if (p === "Fajr") pFile = "fjar-reminder.mp3"; 
                        else if (p === "Dhuhr") pFile = "dhuhr-reminder.mp3";
                        else if (p === "Asr") pFile = "asr-reminder.mp3";
                        else if (p === "Maghrib") pFile = "maghrib-reminder.mp3";
                        else if (p === "Isha") pFile = "isha-reminder.mp3";

                        if (pFile !== "") {
                            playAudio(pFile);
                        }
                    }
                }
            }
        }

        
        if (currentMinStr === root.weekdayPlayTime) {
            if (root.lastPlayedWeekdayDay !== currentDay) {
                root.lastPlayedWeekdayDay = currentDay;
                
                
                var weekdays = [
                    "ahad.mp3", 
                    "ithnain.mp3", 
                    "thulatha.mp3", 
                    "Arbi'a.mp3", 
                    "khamis.mp3", 
                    "jumuah.mp3", 
                    "sebt.mp3"
                ];
                
                playAudio(weekdays[dayOfWeek]);
            }
        }

        
        if (currentMinStr === root.sabahAdhkarTime) {
            if (root.lastPlayedSabahDay !== currentDay) {
                root.lastPlayedSabahDay = currentDay;
                playAudio("sabah-adhkar.mp3");
            }
        }

        
        if (currentMinStr === root.masaAdhkarTime) {
            if (root.lastPlayedMasaDay !== currentDay) {
                root.lastPlayedMasaDay = currentDay;
                playAudio("masa-adhkar.mp3");
            }
        }

        
        if (root.duaTimes.indexOf(currentMinStr) !== -1) {
            if (root.lastPlayedDuaTime !== currentMinStr || root.lastPlayedDuaDay !== currentDay) {
                root.lastPlayedDuaTime = currentMinStr;
                root.lastPlayedDuaDay = currentDay;
                playAudio("dua-reminder.mp3");
            }
        }
    }
}
