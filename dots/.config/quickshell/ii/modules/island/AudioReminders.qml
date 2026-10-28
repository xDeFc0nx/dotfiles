pragma Singleton
import QtQuick
import Quickshell
import qs.services

QtObject {
    id: root

    readonly property string audioDirectory: Quickshell.configDir + "/assets/audio"
    readonly property string playerScript: Quickshell.shellPath("scripts/adhan/play-adhan.sh")

    readonly property int leadMinutes: 10

    readonly property string weekdayPlayTime: "08:00"
    readonly property string sabahAdhkarTime: "07:00"
    readonly property string masaAdhkarTime: "17:00"
    readonly property var duaTimes: ["12:00", "18:00", "21:00"]

    readonly property var prayerNames: ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    readonly property var prayerFiles: ({
        "Fajr": "fjar-reminder.mp3",
        "Dhuhr": "dhuhr-reminder.mp3",
        "Asr": "asr-reminder.mp3",
        "Maghrib": "maghrib-reminder.mp3",
        "Isha": "isha-reminder.mp3"
    })
    readonly property var weekdayFiles: [
        "ahad.mp3", "ithnain.mp3", "thulatha.mp3", "Arbi'a.mp3",
        "khamis.mp3", "jumuah.mp3", "sebt.mp3"
    ]

    // Real system notification, so it reaches the island toast and the notification
    // history instead of only a transient in-process signal.
    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Adhan", "-i", "audio-volume-high", "-u", "normal", title, body]);
    }

    property string lastPlayedKey: ""
    property string lastPlayedStamp: ""

    property Timer scheduler: Timer {
        repeat: false
        onTriggered: {
            root.fireDueEvents()
            root.armNext()
        }
    }

    function parseTime(value) {
        if (!value) return -1;
        const parts = String(value).trim().split(":");
        if (parts.length < 2) return -1;
        const hours = parseInt(parts[0]);
        const minutes = parseInt(parts[1]);
        if (isNaN(hours) || isNaN(minutes)) return -1;
        return hours * 60 + minutes;
    }

    function formatMinute(minute) {
        const h = Math.floor(minute / 60) % 24;
        const m = minute % 60;
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
    }

    // Every reminder for one day, as minute-of-day values. Prayers are shifted back by
    // leadMinutes so the voice reminder lands before the adhan, not on top of it.
    function buildEvents(dayOfWeek) {
        const list = [];

        for (let i = 0; i < root.prayerNames.length; i++) {
            const name = root.prayerNames[i];
            const adhan = root.parseTime(PrayerTimes.timings[name]);
            if (adhan < 0) continue;
            list.push({
                key: "prayer-" + name,
                minute: (adhan - root.leadMinutes + 1440) % 1440,
                file: root.prayerFiles[name],
                title: name + " in " + root.leadMinutes + " minutes",
                body: "Adhan at " + root.formatMinute(adhan)
            });
        }

        const fixed = [
            { key: "weekday", minute: root.parseTime(root.weekdayPlayTime), file: root.weekdayFiles[dayOfWeek], title: "Daily remembrance", body: "" },
            { key: "adhkar-morning", minute: root.parseTime(root.sabahAdhkarTime), file: "sabah-adhkar.mp3", title: "Morning adhkar", body: "" },
            { key: "adhkar-evening", minute: root.parseTime(root.masaAdhkarTime), file: "masa-adhkar.mp3", title: "Evening adhkar", body: "" }
        ];

        for (let i = 0; i < fixed.length; i++) {
            if (fixed[i].minute >= 0)
                list.push(fixed[i]);
        }

        for (let i = 0; i < root.duaTimes.length; i++) {
            const minute = root.parseTime(root.duaTimes[i]);
            if (minute >= 0)
                list.push({ key: "dua-" + root.duaTimes[i], minute: minute, file: "dua-reminder.mp3", title: "Dua reminder", body: "" });
        }

        return list;
    }

    function play(fileName) {
        if (!fileName) return;
        Quickshell.execDetached([root.playerScript, root.audioDirectory + "/" + fileName]);
    }

    function dayStamp(date) {
        return date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
    }

    function fireDueEvents() {
        const now = new Date();
        const stamp = root.dayStamp(now);
        const currentMinute = now.getHours() * 60 + now.getMinutes();
        const events = root.buildEvents(now.getDay());

        for (let i = 0; i < events.length; i++) {
            const event = events[i];
            if (Math.abs(event.minute - currentMinute) > 1) continue;
            if (root.lastPlayedKey === event.key && root.lastPlayedStamp === stamp) continue;

            root.lastPlayedKey = event.key;
            root.lastPlayedStamp = stamp;
            root.notify(event.title, event.body);
            root.play(event.file);
        }
    }

    function armNext() {
        root.scheduler.stop();

        if (!PrayerTimes.timings || Object.keys(PrayerTimes.timings).length === 0) {
            root.scheduler.interval = 60000;
            root.scheduler.start();
            return;
        }

        const now = new Date();
        const events = root.buildEvents(now.getDay());
        let nextAt = null;

        for (let i = 0; i < events.length; i++) {
            const at = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, events[i].minute, 0, 0);
            if (at <= now) at.setDate(at.getDate() + 1);
            if (nextAt === null || at < nextAt) nextAt = at;
        }

        if (nextAt === null) return;
        root.scheduler.interval = Math.max(1000, nextAt.getTime() - now.getTime());
        root.scheduler.start();
    }

    Component.onCompleted: root.armNext()
}
