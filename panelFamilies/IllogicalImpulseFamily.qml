import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.dock
import qs.modules.ii.equalizer
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.settings
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector
import qs.modules.ii.desktopMenu
import qs.modules.ii.dropover
import qs.modules.ii.frame

import qs.modules.ii.clock
import qs.modules.ii.easyEffects
import qs.modules.ii.modes
import qs.modules.ii.notes
import qs.modules.ii.cheatsheet
import qs.modules.ii.alarmRingingPopup
import qs.modules.ii.reminderAlertPopup

Scope {
    PanelUrlLoader { extraCondition: !Config.options.bar.vertical; panelUrl: Qt.resolvedUrl("../modules/ii/bar/Bar.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/background/Background.qml") }
    PanelUrlLoader { extraCondition: Config.options.dock.enable; panelUrl: Qt.resolvedUrl("../modules/ii/dock/Dock.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/equalizer/EqualizerPopup.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/lock/Lock.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/mediaControls/MediaControls.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/notificationPopup/NotificationPopup.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/onScreenDisplay/OnScreenDisplay.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/onScreenKeyboard/OnScreenKeyboard.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/overlay/Overlay.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/overview/Overview.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/polkit/Polkit.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/regionSelector/RegionSelector.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/screenCorners/ScreenCorners.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/screenTranslator/ScreenTranslator.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/sessionScreen/SessionScreen.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/sidebarLeft/SidebarLeft.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/sidebarRight/SidebarRight.qml") }
    PanelUrlLoader { extraCondition: Config.options.bar.vertical; panelUrl: Qt.resolvedUrl("../modules/ii/verticalBar/VerticalBar.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/wallpaperSelector/WallpaperSelector.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/clock/ClockApp.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/easyEffects/EasyEffectsApp.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/modes/ModesApp.qml") }
    PanelUrlLoader { extraCondition: Config.options.notes.enable; panelUrl: Qt.resolvedUrl("../modules/ii/notes/NotesApp.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/cheatsheet/Cheatsheet.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/alarmRingingPopup/AlarmRingingPopup.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/reminderAlertPopup/ReminderAlertPopup.qml") }
    // Legacy 2-column layer-shell settings disabled in favor of SettingsWindow.qml in shell.qml
    // PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii//Settings.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/desktopMenu/DesktopMenu.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/dropover/DropShelfPanel.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/background/NiriBackdrop.qml") }
    PanelUrlLoader { panelUrl: Qt.resolvedUrl("../modules/ii/frame/ScreenFrame.qml") }
}
