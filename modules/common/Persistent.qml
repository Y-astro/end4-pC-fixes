pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property alias states: persistentStatesJsonAdapter
    property string fileDir: Directories.state
    property string fileName: "states.json"
    property string filePath: `${root.fileDir}/${root.fileName}`

    property bool ready: false
    property string previousHyprlandInstanceSignature: ""
    property bool isNewHyprlandInstance: previousHyprlandInstanceSignature !== states.hyprlandInstanceSignature

    onReadyChanged: {
        root.previousHyprlandInstanceSignature = root.states.hyprlandInstanceSignature
        root.states.hyprlandInstanceSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || ""
    }

    Timer {
        id: fileReloadTimer
        interval: 100
        repeat: false
        onTriggered: {
            persistentStatesFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: 100
        repeat: false
        onTriggered: {
            persistentStatesFileView.writeAdapter()
        }
    }

    FileView {
        id: persistentStatesFileView
        path: root.filePath

        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            console.log("Failed to load persistent states file:", error);
            if (error == FileViewError.FileNotFound) {
                fileWriteTimer.restart();
            }
        }

        adapter: JsonAdapter {
            property string desktopShortcutsJson: "{}"
            property JsonObject migrations: JsonObject {
                property int presetUserDataVersion: 0
            }
            property JsonObject typingTest: JsonObject {
                property list<var> recentResults: []
                property list<var> personalBests: []
                // Lifetime tallies. They outlive `recentResults`, which is
                // capped, so "tests completed" stays true after the oldest
                // results have been pruned away.
                property int testsStarted: 0
                property int testsCompleted: 0
                property real secondsTyping: 0
                // [{ d: "YYYY-MM-DD", n: tests }], one entry per active day,
                // bounded to roughly a year — enough for the activity map and
                // far smaller than keeping every result to derive it.
                property list<var> activity: []
            }
            property JsonObject shellBackup: JsonObject {
                property bool enabled: false
                property string folder: ""
                // Hand the folder to the Google Drive sync that already runs,
                // rather than uploading anything from here.
                property bool autoDrive: false
                property int keepCount: 5
                property int intervalDays: 7
                property string lastBackupTime: ""
                property string lastBackupPath: ""
                property real lastBackupSizeBytes: 0
            }
            property JsonObject googleDrive: JsonObject {
                property bool enabled: false
                property string syncInterval: "3d" // "1h", "4h", "1d", "2d", "3d"
                property bool syncOnBoot: true
                property bool syncOnNetworkChange: false
                property int bandwidthLimitKbps: 0
                property bool pauseOnMeteredConnection: true
                property list<string> backupFolders: []
                property list<string> excludePatterns: ["*.tmp", "*.swp", "*.lock", "node_modules/", ".git/", "__pycache__/"]
                property string driveBasePath: ""
                property bool notifyOnComplete: true
                property bool notifyOnError: true
                property int keepVersions: 3
                property bool deleteRemoteOrphans: false
                property bool onlyModifiedSinceLastSync: false
                property string lastSyncTime: ""
                property string lastSyncStatus: ""
                property int lastSyncFileCount: 0
                property real lastSyncSizeMb: 0.0
                property list<var> syncHistory: []
                property real totalDriveUsageMb: 0.0
                property real driveQuotaMb: 0.0
                property real driveBackupUsageMb: 0.0
            }
            property JsonObject background: JsonObject {
                property bool widgetsMigrated: false
                property bool lockBehaviorMigrated: false
                // The last wallpapers applied, newest first (see
                // Wallpapers.recordRecent). The desktop menu's strip.
                property list<string> recentWallpapers: []
                // Preset names, most recently applied first (PresetStore.applyPreset).
                property list<string> recentPresets: []
                // How Edit Mode's Style catalogue orders the presets:
                // "recent", "name" or "newest", and whether it is reversed.
                property string presetSort: "recent"
                property bool presetSortReversed: false
                property JsonObject mediaMode: JsonObject {
                    property real userScrollOffset: 0
                    property real localMediaVolume: 0.8
                    property string queueSortCriterion: "title"
                    property bool queueSortDescending: false
                    property bool coverExpanded: false
                    // Immersive artwork layout: "side" keeps the whole cover beside the panels, "cover" crops it to fill the screen.
                    property string immersiveArtLayout: "side"
                }
            }
            property JsonObject clockApp: JsonObject {
                property real width: 1040
                property real height: 760
                property string tab: "alarms"
                property bool railExpanded: true
            }
            property JsonObject easyEffectsApp: JsonObject {
                property string tab: "presets"
                property string pipeline: "output"
                property bool railExpanded: true
            }
            property JsonObject usageApp: JsonObject {
                property bool railExpanded: true
            }
            property JsonObject modesApp: JsonObject {
                property bool railExpanded: true
            }
            property JsonObject notes: JsonObject {
                property real width: 1500
                property real height: 940
                /// Empty means "no note open"; the app falls back to the most recent.
                property string noteId: ""
                /// "all" | "recent" | "favorites" | "trash" | a notebook or section id.
                property string scope: "all"
                /// Both panes are dragged by the user, so both are facts about how they
                /// like to work rather than about this machine's screen — but they live
                /// here beside the window size, which is.
                property real railWidth: 300
                property real listWidth: 360
                property bool railExpanded: true
                property bool linkPreviews: true
                property list<string> aiCustomStyles: []
                property bool driveBackup: false
                /**
                 * The PIN that hides locked notes, as `md5(salt + pin)`.
                 *
                 * A digest rather than the PIN itself, and empty until one is set — there
                 * is no default, because a lock everybody's shell opens with 1234 is worse
                 * than no lock: it looks like protection.
                 *
                 * It is not protection either way, and the app says so where it is set:
                 * the notes on disk are plain files, so this hides a note from somebody
                 * looking over a shoulder and from nobody else. Real encryption is future
                 * work.
                 */
                property string lockDigest: ""
                property string lockSalt: ""
            }
            property JsonObject clipboard: JsonObject {
                property list<string> pinnedEntries: []
                // cliphist exposes stable IDs but no timestamps. These compact
                // records let its opt-in retention policy age entries without
                // guessing from their content or deleting pinned data.
                property list<var> historySeen: []
            }
            property JsonObject tablet: JsonObject {
                // Home-screen icons, keyed by workspace id:
                //   { "1": [ { "id": "firefox", "x": 120, "y": 200 }, ... ], ... }
                //
                // A JSON string rather than a typed structure on purpose. This is a nested,
                // variable-shaped map that grows an entry per workspace the user drops
                // something on, and Config/Persistent's typed lists are documented as
                // fragile for exactly that shape (see AGENTS.md on array typing). It is
                // also state rather than preference — where the user last put an icon —
                // which is why it lives here and not in Config.
                property string homeIconsJson: "{}"
                /**
                 * Which set of missing helpers the first-launch prompt was dismissed for.
                 *
                 * The *set*, not a boolean: "Do it later" means later, and re-asking on
                 * every launch would make it a nag. But a helper going missing later — a
                 * deleted binary, a second one that was never built — is a different
                 * situation and deserves to be raised again, which a boolean could not
                 * express. Empty means never dismissed.
                 */
                property string helperSetupDismissed: ""

                // Where the floating bubble was left, as a fraction of the screen, so it
                // lands in the same corner on a different monitor rather than off the edge
                // of a smaller one. -1 means "never moved": the first placement is the
                // default corner, not a stored 0,0.
                property real bubbleX: -1
                property real bubbleY: -1
                /// Which side the action panel opened towards last, so it does not flip
                /// while the panel is on screen.
                property bool bubbleOnRight: true
            }
            property JsonObject hyprland: JsonObject {
                property string layout: "dwindle"
            }
            property JsonObject overview: JsonObject {
                // Real Gnome: screen name -> { x, y, width, height } of the free area
                // under the workspace thumbnails, last measured. The first open after a
                // start lands the plane there instead of on an estimate.
                property var realGnomeAreas: ({})
            }
            property JsonObject keyboardBacklight: JsonObject {
                property bool idleOffActive: false // Whether the idle monitor is the reason it's off
                property int savedLevel: 0 // Level to return to once input resumes
            }
            property JsonObject nightLight: JsonObject {
                property bool hasManual: false // Whether a manual toggle is currently overriding automatic mode
                property bool manualActive: false
                property real manualSetAt: 0 // Epoch ms, used to tell whether the override has expired
                property int gamma: 100
                property string gammaByMonitorJson: "{}"
                property string sessionId: ""
            }
            property JsonObject displayColorFilter: JsonObject {
                property string profilesJson: "{}"
            }
            property JsonObject modes: JsonObject {
                property string activeId: ""
                property string activeSource: "" // manual | schedule | app | game | …
                property real activeSince: 0 // Epoch ms; must be real
                property real activeEndsAt: 0 // Epoch ms, 0 = open-ended
                property list<var> snapshot: [] // [{type, was, set, extra, action}] in apply order
                property list<string> failed: []
                property string lastUsedModeId: ""
                property list<string> suppressed: [] // stopped by hand while triggers still held
                property list<string> suppressedRoutines: [] // same, for `while` routines
                property list<var> history: [] // newest first, capped
                // Running `while` routines: [{id, source, since, snapshot, failed}]
                property list<var> routineRuns: []
                // Last fire time of `once` routines for cooldowns: [{id, t}]
                property list<var> routineFired: []
                // Action sequences paused on a wait or a delay, resumed by the
                // engine when due: [{kind, id, index, dueAt, resumed, source, failed}]
                property list<var> pendingSteps: []
            }
            property JsonObject phoneCamera: JsonObject {
                property string lastMode: "wifi"   // "wifi" | "usb"
                property string lastIp: ""
                property int lastPort: 4747
            }
            property JsonObject phoneMic: JsonObject {
                property string originalDefaultSink: ""
                property string lastBackend: ""     // "scrcpy" | "droidcam"
                property string lastMode: "wifi"
                property string lastIp: ""
                property int lastPort: 4748
            }
            property JsonObject screenRecord: JsonObject {
                property bool active: false
                property int seconds: 0
                property bool loading: false
                property bool paused: false
            }
            property JsonObject bar: JsonObject {
                // The centre layout stashed when "Dynamic Island in bar center"
                // took the group over. Restored on the way out if the user has
                // not rebuilt the centre meanwhile; see DynamicIslandConfig.
                property list<var> centerStash: []
            }
            property list<var> alarms: []
            property JsonObject alarmState: JsonObject {
                property real lastCheck: 0
                property list<var> missed: []
            }
            property JsonObject bedtime: JsonObject {
                property list<var> nights: []
                property string windDownNotified: ""
                property string bedtimeNotified: ""
                property real lastNudge: 0
            }
            property JsonObject screenTime: JsonObject {
                property string date: ""
                property string dayJson: "{}"
            }
            property JsonObject water: JsonObject {
                property int glassesDrunk: 0
                property string lastDate: ""
                property real lastNotify: 0
                // { "<y-m-d>": glasses } for the last two weeks (the dock card's week).
                property string historyJson: "{}"
            }
            property JsonObject dockUtilities: JsonObject {
                // Files and Screenshots: when their panel was last opened (ms);
                // anything newer counts as new.
                property real filesSeen: 0
                property real screenshotsSeen: 0
                property list<string> shelf: []
                property list<string> colors: []
            }
            property JsonObject media: JsonObject {
            }
            property JsonObject wallpaper: JsonObject {
                property list<string> favourites: []
                property list<string> favouriteDirectories: []
            }

            id: persistentStatesJsonAdapter

            property string hyprlandInstanceSignature: ""

            property JsonObject settings: JsonObject {
                property list<string> collapsedGroups: []
                property bool whatsNewCollapsed: true
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrainsMono Nerd Font"
                    property string monospace: "JetBrainsMono Nerd Font"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                    property bool roundnessFull: false
                }
            }

            property JsonObject search: JsonObject {
                property list<var> aliases: []
                property list<string> recentEmojis: []
                property list<string> recentQueries: []
                property list<string> pinnedEntries: []
                property list<var> panelUsage: []
                property list<var> calculatorHistory: []
                property real exchangeRatesUpdatedAt: 0
                property list<var> resultKeybinds: []
            }

            property JsonObject ai: JsonObject {
                property string modelId: "google:gemini-3.8-flash"
                property string defaultModelId: ""
                property real defaultTemperature: -1
                property string defaultThinkingLevel: ""
                property string defaultPersonaId: ""
                property string provider: ""
                property string thinkingLevel: "medium"
                property list<string> recentModels: []
                property list<string> collapsedModelGroups: []
                property string personaId: ""

                property string model: "gemini-2.5-flash"
                property real temperature: 0.5
            }

            property JsonObject cheatsheet: JsonObject {
                property list<string> sectionOrder: []
                property string keybindPageId: ""
                property bool keybindSidebarVisible: true
                property string timetableView: "month"
                property bool timetableShowUpcoming: true
                property string timetableMonthDensity: "compact"
                property bool timetableCollapseRecurring: true
                property list<string> timetableCollapsedUpcomingGroups: []
                property int timetableSlotHeight: 168
                property int timetableSlotHeightVersion: 0
                property list<string> timetableNotified: []
                property list<var> timetableSnoozes: []
                property list<string> timetableGmailIcsImports: []
                property list<string> timetableOutlookIcsImports: []
                property string devToolsToolId: ""
                property string devToolsCategory: "all"

                property int tabIndex: 0
            }

            property JsonObject sidebar: JsonObject {
                property JsonObject bottomGroup: JsonObject {
                    property int todoTab: 0
                    property int timerTab: 0
                    property list<string> todoNotifiedToday: []

                    property bool collapsed: false
                    property int tab: 0
                }
                property JsonObject policies: JsonObject {
                    property int tab: 0
                    property JsonObject phone: JsonObject {
                        property string activeDeviceId: ""
                        property list<string> recentDeviceIds: []
                        property string cachedNotificationsJson: ""
                        property JsonObject scrcpy: JsonObject {
                            property list<string> recentPackages: []
                        }
                        property JsonObject peripherals: JsonObject {
                            property bool collapsed: false
                            property int tab: 0
                        }
                    }
                }
            }

            property JsonObject booru: JsonObject {
                property bool allowNsfw: false
                property string provider: "yandere"
            }

            property JsonObject idle: JsonObject {
                property real expiresAt: 0 // Epoch ms; 0 means indefinite. Must be real, not int
                property real durationMinutes: 0 // Preset the timed session started from, 0 if none
                property string sessionId: ""

                property bool inhibit: false
            }

            property JsonObject record: JsonObject {
                property bool enable: false
            }

            property JsonObject overlay: JsonObject {
                property JsonObject media: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: true
                    property real x: 827
                    property real y: 441
                    property real width: 250
                    property real height: 100
                }
                property JsonObject discordVoice: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: false
                    property real x: 80
                    property real y: 600
                    property real width: 344
                    property real height: 200
                }
                property JsonObject perfMonitor: JsonObject {
                    property bool pinned: true
                    property bool clickthrough: true
                    property real x: 24
                    property real y: 80
                    property real width: 0
                    property real height: 0
                }

                property list<string> open: ["crosshair", "recorder", "volumeMixer", "resources"]
                property JsonObject crosshair: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: true
                    property real x: 827
                    property real y: 441
                    property real width: 250
                    property real height: 100
                }
                property JsonObject floatingImage: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: false
                    property real x: 1650
                    property real y: 390
                    property real width: 0
                    property real height: 0
                }
                property JsonObject fpsLimiter: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: false
                    property real x: 1570
                    property real y: 615
                    property real width: 280
                    property real height: 80
                }
                property JsonObject recorder: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: false
                    property real x: 80
                    property real y: 80
                    property real width: 350
                    property real height: 130
                }
                property JsonObject resources: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: true
                    property real x: 1500
                    property real y: 770
                    property real width: 350
                    property real height: 200
                    property int tabIndex: 0
                }
                property JsonObject volumeMixer: JsonObject {
                    property bool pinned: false
                    property bool clickthrough: false
                    property real x: 80
                    property real y: 280
                    property real width: 350
                    property real height: 600
                    property int tabIndex: 0
                }
                property JsonObject notes: JsonObject {
                    property int tabIndex: 0

                    property bool pinned: false
                    property bool clickthrough: true
                    property real x: 1400
                    property real y: 42
                    property real width: 460
                    property real height: 330
                }
            }

            property JsonObject timer: JsonObject {
                property list<var> countdowns: []
                property JsonObject countdownDraft: JsonObject {
                    property int hours: 0
                    property int minutes: 5
                    property int seconds: 0
                }

                property JsonObject pomodoro: JsonObject {
                    property string todayDate: ""
                    property int todayCount: 0

                    property bool running: false
                    property int start: 0
                    property bool isBreak: false
                    property int cycle: 0
                }
                property JsonObject stopwatch: JsonObject {
                    property bool running: false
                    property int start: 0
                    property list<var> laps: []
                }
                property JsonObject countdown: JsonObject {
                    property bool running: false
                    property int duration: 0
                    property int start: 0
                }
            }
        }
    }
}
