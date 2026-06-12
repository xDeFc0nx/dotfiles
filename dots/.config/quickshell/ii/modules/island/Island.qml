pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.island

Scope {
    id: island

    Component.onCompleted: {
        var initAudio = AudioReminders;
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        
        LazyLoader {
            id: islandLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            
            component: IslandWindow {
                screen: islandLoader.modelData
            }
        }
    }
}
