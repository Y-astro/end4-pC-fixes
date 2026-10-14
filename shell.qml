//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1
import "modules/common"
import "services"
import "panelFamilies"
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    ReloadPopup {}

    Process {
        id: autostartProc
        command: ["python3", `${Directories.scriptPath}/hyprland/autostart.py`]
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return

            if (WM.compositor === "niri") {
                Config.options.background.lockWall = ""
                Config.options.overview.enable = false
            }

            if (Config.options.hyprland.autostartApps.enable &&
                Config.options.hyprland.autostartApps.apps.length > 0) {
                autostartProc.running = true
            }
        }
    }

    // First paint needs only the theme, wallpaper and compatibility checks.
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        FirstRunExperience.load();
        ConflictKiller.load();
        Wallpapers.load();
        deferredServicesTimer.restart();
    }

    Timer {
        id: deferredServicesTimer
        interval: 3000
        onTriggered: {
            Hyprsunset.load();
            Cliphist.refresh();
            Updates.load();
            LyricsService.restartLyrics();
            KdeConnectService.load();
            PresetStore.ensureLoaded();
            // Scheduling belongs to services, so alerts survive closed app windows.
            AlarmService.alarms;
            RemindersService.loaded;
            BedtimeService.enabled;
            Modes.enabled;
            if (Config.options?.notes?.enable ?? true)
                NotesService.ready;
            if (Config.options?.clockApp?.phoneAlarm?.enable ?? false)
                PhoneAlarmService.enabled;
            if (Config.options?.calendar?.timetable?.notifications?.enable ?? false)
                CalendarNotifier.enabled;
        }
    }

    Loader {
        id: settingsLoader
        readonly property int unloadDelay: Config.options?.appearance?.settingsUnloadDelay ?? 0
        readonly property bool keepAliveWanted: unloadDelay !== 0
        property bool keptAlive: false

        active: GlobalStates.settingsOpen || GlobalStates.settingsSuspendedForScreenshot || keptAlive
        asynchronous: false
        source: "SettingsWindow.qml"
        onActiveChanged: {
            if (!active && settingsGarbageCollect)
                settingsGarbageCollect.restart();
        }
        onUnloadDelayChanged: {
            settingsUnloadTimer.stop();
            if (!keepAliveWanted) {
                keptAlive = false;
            } else if (GlobalStates.settingsOpen) {
                keptAlive = true;
            } else if (keptAlive && unloadDelay > 0) {
                settingsUnloadTimer.restart();
            }
        }
    }

    Timer {
        id: settingsUnloadTimer
        interval: Math.max(1, settingsLoader.unloadDelay) * 1000
        onTriggered: {
            if (!GlobalStates.settingsOpen)
                settingsLoader.keptAlive = false;
        }
    }

    Connections {
        target: GlobalStates
        function onSettingsOpenChanged() {
            if (GlobalStates.settingsOpen) {
                settingsUnloadTimer.stop();
                settingsLoader.keptAlive = settingsLoader.keepAliveWanted;
            } else if (settingsLoader.keptAlive && settingsLoader.unloadDelay > 0) {
                settingsUnloadTimer.restart();
            }
        }
    }

    Timer {
        id: settingsGarbageCollect
        interval: 0
        onTriggered: {
            if (!settingsLoader.active)
                gc();
        }
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        active: Config.ready && Config.options.panelFamily === identifier
    }
}