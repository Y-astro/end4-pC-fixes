pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.worldclock
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.notes
import qs.modules.ii.background.widgets.todo
import qs.modules.ii.background.widgets.timers
import qs.modules.ii.background.widgets.utility

Item {
    id: root

    required property var screen
    required property var wallpaperItem
    required property bool wallpaperSafetyTriggered

    readonly property bool onThisScreen: Config.options.background.screenList.length === 0
        || Config.options.background.screenList.includes(root.screen.name)

    Repeater {
        model: [
            { key: "visualizer" },
            { key: "visualizer2" },
            { key: "customImage" },
            { key: "calendar" },
            { key: "weather" },
            { key: "clock", alwaysOnLock: true },
            { key: "notes" },
            { key: "media" },
            { key: "images" },
            { key: "resources" },
            { key: "worldClock" },
            { key: "userCard" },
            { key: "todo" },
            { key: "timers" },
            // Addon Clocks
            { key: "clock_nothing", alwaysOnLock: true },
            { key: "nothing_wheel_clock", alwaysOnLock: true },
            { key: "clock_wearos", alwaysOnLock: true },
            { key: "clock_wearos_arc", alwaysOnLock: true },
            { key: "clock_nagasaki", alwaysOnLock: true },
            { key: "nagasaki_text", alwaysOnLock: true },
            { key: "clock_flex", alwaysOnLock: true },
            { key: "clock_hori", alwaysOnLock: true },
            { key: "clock_ios", alwaysOnLock: true },
            { key: "clock_word", alwaysOnLock: true },
            { key: "clock_scallop_dot", alwaysOnLock: true },
            { key: "clock_scallop_number", alwaysOnLock: true },
            { key: "clock_concentric", alwaysOnLock: true },
            { key: "clock_dial", alwaysOnLock: true },
            { key: "clock_triple_ring", alwaysOnLock: true },
            { key: "clock_month", alwaysOnLock: true },
            // Addon Utilities
            { key: "nothing_cpu" },
            { key: "nothing_ram" },
            { key: "nothing_disk" },
            { key: "cpu_pill" },
            { key: "ram_pill" },
            { key: "disk_pill" },
            { key: "at_a_glance" },
            { key: "android_search_bar" },
            { key: "quote_widget" },
            { key: "water_reminder" },
            { key: "resource_fill_cards" },
            { key: "quick_actions" },
            { key: "ai_chat" },
            // Addon Media
            { key: "media_cd" },
            { key: "media_circular" },
            { key: "media_compact" },
            { key: "media_nothing_ring" },
            { key: "media_android" },
            { key: "media_expressive" },
        ]

        delegate: FadeLoader {
            id: loaderDelegate
            required property var modelData

            property bool enableLoading: true

            shown: (Config.options.background.widgets[loaderDelegate.modelData.key]?.enable ?? false)
                && (loaderDelegate.modelData.key !== "visualizer" || ["ring", "wuwa"].includes(Config.options.background.widgets.visualizer?.style ?? "bars"))
                && (loaderDelegate.modelData.key !== "visualizer2" || ["ring", "wuwa"].includes(Config.options.background.widgets.visualizer2?.style ?? "ring"))
                && loaderDelegate.enableLoading
                && (loaderDelegate.modelData.alwaysOnLock
                    ? (GlobalStates.screenLocked || root.onThisScreen)
                    : root.onThisScreen)

            sourceComponent: {
                switch (loaderDelegate.modelData.key) {
                    case "visualizer":  return visualizerRingComp
                    case "visualizer2": return visualizer2RingComp
                    case "customImage": return customImageComp
                    case "calendar":    return calendarComp
                    case "weather":     return weatherComp
                    case "clock":       return clockComp
                    case "notes":       return notesComp
                    case "media":       return mediaComp
                    case "images":      return imagesComp
                    case "resources":   return resourcesComp
                    case "worldClock":  return worldClockComp
                    case "userCard":    return userCardComp
                    case "todo":        return todoComp
                    case "timers":      return timersComp
                    // Addon Clocks
                    case "clock_nothing":        return clockNothingComp
                    case "nothing_wheel_clock":  return nothingWheelClockComp
                    case "clock_wearos":         return clockWearosComp
                    case "clock_wearos_arc":     return clockWearosArcComp
                    case "clock_nagasaki":       return clockNagasakiComp
                    case "nagasaki_text":        return nagasakiTextComp
                    case "clock_flex":           return clockFlexComp
                    case "clock_hori":           return clockHoriComp
                    case "clock_ios":            return clockIosComp
                    case "clock_word":           return clockWordComp
                    case "clock_scallop_dot":    return clockScallopDotComp
                    case "clock_scallop_number": return clockScallopNumberComp
                    case "clock_concentric":     return clockConcentricComp
                    case "clock_dial":           return clockDialComp
                    case "clock_triple_ring":    return clockTripleRingComp
                    case "clock_month":          return clockMonthComp
                    // Addon Utilities
                    case "nothing_cpu":          return nothingCpuComp
                    case "nothing_ram":          return nothingRamComp
                    case "nothing_disk":         return nothingDiskComp
                    case "cpu_pill":             return cpuPillComp
                    case "ram_pill":             return ramPillComp
                    case "disk_pill":            return diskPillComp
                    case "at_a_glance":          return atAGlanceComp
                    case "android_search_bar":   return androidSearchBarComp
                    case "quote_widget":         return quoteWidgetComp
                    case "water_reminder":       return waterReminderComp
                    case "resource_fill_cards":  return resourceFillCardsComp
                    case "quick_actions":        return quickActionsComp
                    case "ai_chat":              return aiChatComp
                    // Addon Media
                    case "media_cd":             return mediaCdComp
                    case "media_circular":       return mediaCircularComp
                    case "media_compact":        return mediaCompactComp
                    case "media_nothing_ring":   return mediaNothingRingComp
                    case "media_android":        return mediaAndroidComp
                    case "media_expressive":     return mediaExpressiveComp
                }
                return null
            }

            onLoaded: {
                if (loaderDelegate.modelData.key === "media" && loaderDelegate.item && loaderDelegate.item.requestReset) {
                    loaderDelegate.item.requestReset.connect(() => {
                        loaderDelegate.enableLoading = false
                        mediaResetTimer.restart()
                    })
                }
            }

            Timer {
                id: mediaResetTimer
                interval: 500
                onTriggered: loaderDelegate.enableLoading = true
            }
        }
    }
    Component {
        id: visualizerRingComp
        VisualizerWidget {
            widgetConfigName: "visualizer"
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: visualizer2RingComp
        VisualizerWidget {
            widgetConfigName: "visualizer2"
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: customImageComp
        CustomImage {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: calendarComp
        CalendarWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: weatherComp
        WeatherWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: clockComp
        ClockWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperSafetyTriggered: root.wallpaperSafetyTriggered
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: notesComp
        NotesWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: mediaComp
        MediaWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: imagesComp
        ImageConverterWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: resourcesComp
        ResourcesWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: worldClockComp
        WorldClockWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: userCardComp
        UserCardWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: todoComp
        TodoWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: timersComp
        TimerWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }

    // ── Addon Clocks ──────────────────────────────────────
    Component { id: clockNothingComp; NothingDigitalClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: nothingWheelClockComp; NothingWheelClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockWearosComp; WearOSClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockWearosArcComp; WearOSArcClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockNagasakiComp; NagasakiClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: nagasakiTextComp; NagasakiTextClock { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockFlexComp; FlexClock { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockHoriComp; HoriClock { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockIosComp; IosClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockWordComp; WordClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockScallopDotComp; ScallopDotClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockScallopNumberComp; ScallopNumberClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockConcentricComp; ConcentricClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockDialComp; DialClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockTripleRingComp; TripleRingClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: clockMonthComp; MonthClockWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }

    // ── Addon Utilities ───────────────────────────────────
    Component { id: nothingCpuComp; NothingCpuWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: nothingRamComp; NothingRamWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: nothingDiskComp; NothingDiskWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: cpuPillComp; CpuPillWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: ramPillComp; RamPillWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: diskPillComp; DiskPillWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: atAGlanceComp; AtAGlanceWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: androidSearchBarComp; AndroidSearchBarWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: quoteWidgetComp; QuoteWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: waterReminderComp; WaterReminderWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: resourceFillCardsComp; ResourceFillCardsWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: quickActionsComp; QuickActionsWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: aiChatComp; AiChatWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }

    // ── Addon Media ───────────────────────────────────────
    Component { id: mediaCdComp; CdMediaWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: mediaCircularComp; CircularMediaWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: mediaCompactComp; CompactMediaWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: mediaNothingRingComp; NothingRingMediaWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: mediaAndroidComp; AndroidMediaWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
    Component { id: mediaExpressiveComp; ExpressiveMediaWidget { screenWidth: root.screen.width; screenHeight: root.screen.height; scaledScreenWidth: root.screen.width; scaledScreenHeight: root.screen.height; wallpaperScale: 1; wallpaperItem: root.wallpaperItem } }
}