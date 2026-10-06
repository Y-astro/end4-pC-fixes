pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.functions

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50 // milliseconds
    property bool blockWrites: false
    property bool configMalformed: false
    property string configHealthState: "ok"
    property list<string> configHealthKeys: []

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        // Traverse and collect parent objects
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        // Convert value to correct type using JSON.parse when safe
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.writeAdapter()
        }
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            property string panelFamily: "ii" // "ii", "waffle"

            property JsonObject userProfile: JsonObject {
                property string imageStyle: "initial" // "initial", "expressive", "custom"
                property string imagePath: Directories.userProfileImagePath
                property string customName: ""
                property string customGreeting: ""
                property string customBio: ""
                property string avatarShape: "Cookie9Sided"
                property string avatarColor: "primary"
            }

            property JsonObject policies: JsonObject {
                property int ai: 1 // 0: No | 1: Yes | 2: Local
                property int weeb: 1 // 0: No | 1: Open | 2: Closet
                property int phone: 1 // 0: No | 1: Yes
                property int wallpapers: 1 // 0: No | 1: Yes
                property int translator: 1 // 0: No | 1: Yes
                property int player: 1 // 0: No | 1: Yes
            }

            property JsonObject phone: JsonObject {
                property bool kdeconnectEnabled: true
                property bool remoteCommands: true
                property bool mirrorNotificationsToDesktop: true
                property bool showPeripheralCards: true
                property JsonObject contacts: JsonObject {
                    property bool enabled: true
                    property list<string> favoriteIds: []
                    property bool showAvatars: true
                    property string sortBy: "first"
                    property bool hideUnnamed: true
                }
                property JsonObject scrcpy: JsonObject {
                    property bool stayAwake: true
                    property bool turnScreenOff: false
                    property bool noPowerOn: false
                    property bool noAudio: false
                    property bool showTouches: false
                    property bool fullscreen: false
                    property bool alwaysOnTop: false
                    property int maxFps: 120
                    property string bitRate: "24M"
                    property int maxSize: 0
                    property int videoBuffer: 0
                    property string videoCodec: "h264"
                    property string videoEncoder: "c2.mtk.avc.encoder"
                    property bool useWireless: false
                    property bool autoWirelessIp: true
                    property bool pinAdbPort: false
                    property bool autoResume: true
                    property string wirelessIp: ""
                    property string wirelessPort: "5555"
                    property bool showTerminal: false
                    property string keyboardMode: "uhid"
                    property bool clipboardSync: true
                    property JsonObject recording: JsonObject {
                        property string folder: ""
                        property bool withAudio: true
                    }
                    property JsonObject embed: JsonObject {
                        property bool enabled: false
                        property int keepWarmSeconds: 120
                    }
                    property JsonObject appMode: JsonObject {
                        property bool enabled: true
                        property bool showAppIcons: true
                        property string iconShape: "oneui"
                        property bool flexDisplay: false
                        property string onSessionEnd: "home"
                        property bool autoUnlock: true
                        property int displayWidth: 1280
                        property int displayHeight: 960
                        property int density: 160
                        property bool keepActive: true
                        property bool systemDecorations: true
                        property list<string> favoritePackages: []
                    }
                }
                property JsonObject webcam: JsonObject {
                    property bool enabled: false
                    property string cameraFacing: "front"
                    property string resolution: "1280x720"
                    property int fps: 30
                    property string bitrate: "4M"
                    property bool mirrorHorizontally: false
                    property int rotateDegrees: 0
                    property string connection: "usb"
                    property string wifiIp: ""
                    property int port: 4747
                }
                property JsonObject microphone: JsonObject {
                    property bool enabled: false
                    property string connection: "usb"
                    property string wifiIp: ""
                    property int port: 4748
                    property bool noiseSuppression: false
                    property bool echoCancellation: false
                    property bool autoGainControl: false
                    property int micGain: 100
                    property bool setAsDefault: false
                }
            }

            property JsonObject ai: JsonObject {
                property string systemPrompt: "## Style\n- Use casual tone, don't be formal!\n- Always be brief and to the point, unless asked otherwise\n- Don't repeat the user's question\n- Be approachable: Avoid using overly complicated, domain-specific terms and provide analogies when asked to explain a concept\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n\nThanks!\n"
                property string tool: "functions" // search, functions, or none
                property list<var> extraModels: [
                    {
                        "api_format": "openai", // Most of the time you want "openai". Use "gemini" for Google's models
                        "description": "This is a custom model. Edit the config to add more! | Anyway, this is DeepSeek R1 Distill LLaMA 70B",
                        "endpoint": "https://openrouter.ai/api/v1/chat/completions",
                        "homepage": "https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free", // Not mandatory
                        "icon": "spark-symbolic", // Not mandatory
                        "key_get_link": "https://openrouter.ai/settings/keys", // Not mandatory
                        "key_id": "openrouter",
                        "model": "deepseek/deepseek-r1-distill-llama-70b:free",
                        "name": "Custom: DS R1 Dstl. LLaMA 70B",
                        "requires_key": true
                    }
                ]
            }

            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 2 // 0: None | 1: Always | 2: When not fullscreen
                property bool sharpMode: false
                property string globalRounding: "large"
                property int roundingValue: 24
                property int defaultBorderRadius: 18
                property bool toggleWindowRounding: true
                property real iconTintPercentage: 0.6
                property real animationMultiplier: 1.0
                property bool settingsPerformanceMode: false
                property int settingsUnloadDelay: 0
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                }
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: true
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }
                property JsonObject wallpaperTheming: JsonObject {
                    property bool enableAppsAndShell: true
                    property bool enableQtApps: true
                    property bool enableTerminal: true
                    property JsonObject terminalGenerationProps: JsonObject {
                        property real harmony: 0.6
                        property real harmonizeThreshold: 100
                        property real termFgBoost: 0.35
                        property bool forceDarkMode: false
                    }
                }
                property JsonObject palette: JsonObject {
                    property string type: "auto" // Allowed: auto, scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot
                    property string accentColor: ""
                }
                property JsonObject appLaunchAnimation: JsonObject {
                    property bool enable: true
                    property string style: "scale" // Allowed: scale, slide
                    property string slideDirection: "auto" // Allowed: auto (nearest edge), bottom, top, left, right
                    property int startPercent: 20 // 5 - 90%, unused by slide
                    property real speed: 4.0 // Duration in tenths of a second
                    property string curve: "iiAppOpen"
                }
            }

            property JsonObject audio: JsonObject {
                // Values in %
                property JsonObject protection: JsonObject {
                    // Prevent sudden bangs
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject profile: JsonObject {
                property string avatarPath: ""
                property string avatarPicture: ""
                property string descriptionText: "::distro::"
                property string displayName: ""
                property bool onlinePresets: false

            }

            property JsonObject hyprland: JsonObject {
                property JsonObject animations: JsonObject {
                    property string animation: "normal"
                    property bool enable: true
                }
                property JsonObject autostartApps: JsonObject {
                    property bool enable: false
                    property list<var> apps: []
                }
                property JsonObject decoration: JsonObject {
                    property int rounding: 22
                    property real activeOpacity: 1.0
                    property real inactiveOpacity: 0.9
                    property JsonObject blur: JsonObject {
                        property bool enabled: true
                        property int size: 1
                        property int passes: 3
                    }
                    property JsonObject shadow: JsonObject {
                        property bool enabled: true
                        property int range: 4
                    }
                }
                property JsonObject general: JsonObject {
                    property int borderSize: 1
                    property int gapsIn: 2
                    property int gapsOut: 5
                    property string layout: "dwindle"
                }
                property JsonObject input: JsonObject {
                    property string kbLayout: "us"
                    property bool numlock: true
                    property int repeatDelay: 250
                    property int repeatRate: 35
                    property int followMouse: 1
                    property JsonObject touchpad: JsonObject {
                        property bool naturalScroll: false
                        property bool disableWhileTyping: true
                        property bool clickfingerBehavior: false
                        property real scrollFactor: 0.7
                    }
                }
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
                property string network: "kcmshell6 kcm_networkmanagement"
                property string manageUser: "kcmshell6 kcm_users"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1" // This is only for shell actions
                property string update: "kitty -1 --hold=yes fish -i -c 'pkexec pacman -Syu'"
                property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
            }

            property JsonObject settings: JsonObject {
                property string style: "default" // default - minimal
                property real borderSize: 1
                property string borderColor: "layer0Border"
            }

            property JsonObject background: JsonObject {
                property string lockWall: ""
                property bool widgetsLocked: false
                property bool showGrid: true
                property bool showBlur: false
                property string splitRatio: "100" // 25 50 100
                property string splitSide: "left"
                property bool showSnapLines: true
                property JsonObject widgets: JsonObject {
                    property bool blurWidgets: false
                    property real blurRadius: 32
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property bool showOnlyWhenLocked: false
                        property string placementStrategy: "leastBusy" // "free", "leastBusy", "mostBusy"
                        property real x: 100
                        property real y: 100
                        property real z: 0
                        property string style: "digital"        // Options: "cookie", "digital"
                        property string color: ""
                        property string styleLocked: "digital"  // Options: "cookie", "digital"
                        property JsonObject cookie: JsonObject {
                            property bool aiStyling: false
                            property int sides: 14
                            property string dialNumberStyle: "full"   // Options: "dots" , "numbers", "full" , "none"
                            property string hourHandStyle: "fill"     // Options: "classic", "fill", "hollow", "hide"
                            property string minuteHandStyle: "medium" // Options "classic", "thin", "medium", "bold", "hide"
                            property string secondHandStyle: "dot"    // Options: "dot", "line", "classic", "hide"
                            property string dateStyle: "bubble"       // Options: "border", "rect", "bubble" , "hide"
                            property bool timeIndicators: false
                            property bool hourMarks: false
                            property bool dateInClock: true
                            property bool constantlyRotate: false
                            property bool useSineCookie: false
                        }
                        property JsonObject digital: JsonObject {
                            property bool adaptiveAlignment: true
                            property bool showDate: true
                            property bool animateChange: true
                            property bool vertical: false
                            property JsonObject font: JsonObject {
                                property string family: "Google Sans Flex"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }
                        property JsonObject pixel: JsonObject {
                            property string orientation: "vertical"
                        }
                        property JsonObject quote: JsonObject {
                            property bool enable: false
                            property string text: ""
                            property bool followClock: false
                        }
                    }
                    property JsonObject weather: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property string sizeMode: "1x3"
                        property bool expanded: false
                    }

                    property JsonObject calendar: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property string sizeMode: "2x2"
                    }
                    property JsonObject worldClock: JsonObject {
                        property bool enable: false
                        property list<string> timezones: ["Australia/Sydney", "Asia/Tokyo", "Europe/London", "America/New_York"]
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property string sizeMode: "2x2"
                        property int clockCount: 4 
                    }

                    property JsonObject notes: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                    }

                    property JsonObject todo: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                    }

                    property JsonObject userCard: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property string sizeMode: "1x2" 
                    }

                    property JsonObject images: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                    }

                    property JsonObject visualizer: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 0
                        property real y: 0
                        property real z: 1
                        property string style: "bars" // "bars", "mirror", "aurora", "ring", "dots", "wuwa"
                        property string colorSource: "theme" // "theme", "cover"
                        property real sensitivity: 1
                        property int height: 260 // bars, mirror, aurora, dots, wuwa
                        property int ringSize: 380
                        property int customWidth: 860
                    }

                    property JsonObject visualizer2: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 0
                        property real y: 0
                        property real z: 15
                        property string style: "ring" // "bars", "mirror", "aurora", "ring", "dots", "wuwa"
                        property string colorSource: "theme" // "theme", "cover"
                        property real sensitivity: 1
                        property int height: 260 // bars, mirror, aurora, dots, wuwa
                        property int ringSize: 380
                        property int customWidth: 860
                    }

                    property JsonObject customImage: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property string path: ""
                        property string shape: "Cookie4Sided"
                        property real size: 200
                    }

                    property JsonObject resources: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property bool vertical: false
                    }

                    property JsonObject timers: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property real z: 0
                        property bool vertical: false
                    }

                    property JsonObject media: JsonObject {
                        property bool enable: false
                        property bool showControls: true
                        property bool showLyrics: false
                        property bool showTitles: true
                        property string backgroundShape: "Cookie4Sided"
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 800
                        property real y: 500
                        property real z: 0
                        property string sizeMode: "1x3" 
                    }

                    property JsonObject customText: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 300
                        property real z: 0
                        property string content: "Hello world"
                        property string fontFamily: "Caveat"
                        property int fontSize: 72
                        property string color: "" // "" = automatic, otherwise an Appearance color name
                        property string alignment: "center" // "left", "center", "right"
                        property bool shadow: true
                    }
                }
                property list<string> screenList: [] 
                property string wallpaperPath: ""
                property bool centeredWallpaper: false
                property string centeredWallpaperShape: "Cookie7Sided"
                property int centeredWallpaperSize: 400
                property string centeredWallpaperColor: "primaryContainer"
                property bool centeredWallpaperOnlyWhenLocked: false
                property string wallpaperAnimation: "magic"
                property bool enableWallpaperPreview: false
                property string thumbnailPath: ""
                property bool hideWhenFullscreen: true
                property JsonObject parallax: JsonObject {
                    property bool vertical: false
                    property bool autoVertical: false
                    property bool enableWorkspace: true
                    property real workspaceZoom: 1.0 // Relative to wallpaper size
                    property bool enableSidebar: true
                    property real widgetsFactor: 1.2
                }
            }

            property JsonObject bar: JsonObject {
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property int hoverRegionWidth: 2
                    property int hoverDelay: 0
                    property string mode: "instant"
                    property bool pushWindows: false
                    property JsonObject showWhenPressingSuper: JsonObject {
                        property bool enable: true
                        property int delay: 140
                    }
                }
                property JsonObject sizes: JsonObject {
                    property int height: 40
                    property int width: 44
                }
                property bool showFrame: false
                property real frameThickness: 4
                property string frameColor: "black"
                property bool followFrameColor: false
                property bool centerOnlyReserveFrame: false
                property bool bottom: false // Instead of top
                property int cornerStyle: 0 // 0: Hug | 1: Float | 2: Plain rectangle
                property int barBackgroundStyle: 0 // 0: Transparent | 1: Visible | 2: Adaptive | 3: Islands
                property int barGroupStyle: 0
                property bool dropShadow: false
                property bool transparentGlow: false
                property bool useMaterialSymbolForTopLeftIcon: false
                property bool expressiveColors: false
                property string expressiveColorTheme: "monochrome"
                property bool expressiveGroupColor: false
                property bool enableVolumeScroll: true
                property bool enableBrightnessScroll: true
                property bool sidebarClickOpen: true
                property bool onlyShowOnSingleMonitor: false
                property string singleMonitorName: ""
                property string groupColor: "layer1"
                property bool floatStyleShadow: true // Show shadow behind bar when cornerStyle == 1 (Float)
                property string borderless: "pills"
                property string topLeftIcon: "spark" // Options: "distro" or any icon name in ~/.config/quickshell/ii/assets/icons
                property bool showBackground: true
                property bool verbose: true
                property bool vertical: false
                property string visualizerStyle: "wuwa" // "wuwa", "bars"
                property int visualizerWidth: 130
                property real visualizerSensitivity: 1
                property JsonObject resources: JsonObject {
                    property string style: "filled"
                    property bool showValue: false
                    property bool alwaysShowSwap: false
                    property bool alwaysShowCpu: true
                    property bool alwaysShowCpuTemp: false
                    property bool alwaysShowDisk: false
                    property bool alwaysShowRam: true
                    property int memoryWarningThreshold: 95
                    property int swapWarningThreshold: 85
                    property int cpuWarningThreshold: 90
                }

                property JsonObject dynamicIsland: JsonObject {
                    property string visualizerStyle: "dots" // "dots", "wave", "none"
                    property bool showMediaControls: false
                }
                property bool dynamicIslandLoadBalance: false
                property int dynamicIslandSpacingHorizontal: 4
                property int dynamicIslandSpacingVertical: 2
                property JsonObject floatingNotch: JsonObject {
                    property bool enable: false
                    property bool centerInBar: false
                }
                property JsonObject divider: JsonObject {
                    property string style: "rect" // rect - dot - space
                    property int spacing: 20
                }
                property JsonObject islandFiller: JsonObject {
                    property bool enable: true
                    property string style: "waves" // "waves", "stream", "bridge", "none"
                    property real opacity: 0.85
                }

                property JsonObject layouts: JsonObject {
                    property list<string> leftLayout: ["launcherButton", "workspaces", "activeWindow"]
                    property list<string> middleLayout: ["clockWidget"]
                    property list<string> rightLayout: ["sysTray", "utilButtons", "systemIcons", "powerButton"]
                    property list<var> left: [
                        { "id": "launcherButton", "visible": true, "centered": false },
                        { "id": "workspaces", "visible": true, "centered": false },
                        { "id": "activeWindow", "visible": true, "centered": false }
                    ]
                    property list<var> center: [
                        { "id": "clockWidget", "visible": true, "centered": false }
                    ]
                    property list<var> right: [
                        { "id": "sysTray", "visible": true, "centered": false },
                        { "id": "utilButtons", "visible": true, "centered": false },
                        { "id": "systemIcons", "visible": true, "centered": false },
                        { "id": "powerButton", "visible": true, "centered": false }
                    ]
                }
                
                property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: true
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: false
                    property bool showWallpaperToggle: true
                    property bool showDarkModeToggle: false
                    property bool showPerformanceProfileToggle: false
                    property bool showScreenRecord: false       
                    property bool isRecording: false
                }

                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property bool showAppIcons: false
                    property bool hideUnused: true
                    property string indicatorStyle: "dot" // "dot", "icon", or "pacman"
                    property bool alwaysShowNumbers: true
                    property int showNumberDelay: 300 // milliseconds
                    property list<string> numberMap: ["1", "2"] // Characters to show instead of numbers on workspace indicator
                    property bool useNerdFont: false
                }
                property JsonObject weather: JsonObject {
                    property bool enable: false
                    property bool enableGPS: true // gps based location
                    property string city: "" // When 'enableGPS' is false
                    property bool useUSCS: false // Instead of metric (SI) units
                    property int fetchInterval: 10 // minutes
                }
                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: false
                    }
                }
                property JsonObject tooltips: JsonObject {
                    property bool enableTooltips: true
                    property bool enablePopups: true
                    property bool clickToShow: false
                    property bool compactPopups: false
                    property real popupScaleMultiplier: 1.0
                    property int closeDelay: 50
                    property bool enableColorPickerPopup: true
                    property bool enableBluetoothConnectionPopup: true
                    property bool enableDisplayModesPopup: true
                    property bool displayModesOnHotplug: true
                    property bool enableKeyboardLayoutTransitionPopup: true
                }
                property JsonObject media: JsonObject {
                    property string preferredPlayer: ""
                    property bool alwaysVisible: false
                    property bool onlyTitle: false
                    property int maxWidth: 280
                    property int minWidth: 100
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: true
                property int suspend: 3
            }

            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
            }

            property JsonObject conflictKiller: JsonObject {
                property bool autoKillNotificationDaemons: false
                property bool autoKillTrays: false
            }

            property JsonObject crosshair: JsonObject {
                // Valorant crosshair format. Use https://www.vcrdb.net/builder
                property string code: "0;P;d;1;0l;10;0o;2;1b;0"
            }

            property JsonObject dock: JsonObject {
                property bool enable: false
                property bool showBackground: true
                property bool showPinButton: true
                property bool showAppsButton: true
                property bool showMedia: true
                property bool monochromeIcons: true
                property real height: 60
                property real hoverRegionHeight: 2
                property bool pinnedOnStartup: false
                property bool hoverToReveal: true // When false, only reveals on empty workspace
                property list<string> pinnedApps: [ // IDs of pinned entries
                    "org.kde.dolphin", "kitty",]
                property list<string> ignoredAppRegexes: []
            }

            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false // Enable faster scrolling with touchpad
                    property int mouseScrollDeltaThreshold: 120 // delta >= this then it gets detected as mouse scroll rather than touchpad
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject { // Hyprland leaves out 1 pixel on the right for interactions
                    property bool enable: false
                }
            }

            property JsonObject language: JsonObject {
                property string ui: "auto" // UI language. "auto" for system locale, or specific language code like "zh_CN", "en_US"
                property JsonObject translator: JsonObject {
                    property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
                    property string targetLanguage: "auto" // Run `trans -list-all` for available languages
                    property string sourceLanguage: "auto"
                }
            }

            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: [ "org.kde.dolphin", "kitty", "cmake-gui"]
            }

            property JsonObject light: JsonObject {
                property JsonObject night: JsonObject {
                    property bool automatic: true
                    property string from: "19:00" // Format: "HH:mm", 24-hour time
                    property string to: "06:30"   // Format: "HH:mm", 24-hour time
                    property int colorTemperature: 5000
                }
                property JsonObject antiFlashbang: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject lock: JsonObject {
                property bool useHyprlock: false
                property bool launchOnStartup: false
                property bool showWidgets: false
                property bool showMedia: true
                property bool showToolbars: true
                property JsonObject blur: JsonObject {
                    property bool enable: true
                    property real radius: 100
                    property real extraZoom: 1.1
                    property int size: 20
                }
                property bool centerClock: true
                property bool showLockedText: true
                property JsonObject security: JsonObject {
                    property bool unlockKeyring: true
                    property bool requirePasswordToPower: false
                }
                property bool materialShapeChars: true
            }

            property JsonObject media: JsonObject {
                // Attempt to remove dupes (the aggregator playerctl one and browsers' native ones when there's plasma browser integration)
                property bool filterDuplicatePlayers: true
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
                property string position: "top_right"
                property int zoomPercent: 100
                property bool autoDndFullscreen: true
                property JsonObject monitor: JsonObject {
                    property bool enable: false
                    property string name: ""
                }
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }

            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
            }

            property JsonObject overlay: JsonObject {
                property bool openingZoomAnimation: true
                property bool darkenScreen: true
                property real clickthroughOpacity: 0.8
                property JsonObject floatingImage: JsonObject {
                    property string imageSource: "https://media.tenor.com/H5U5bJzj3oAAAAAi/kukuru.gif"
                    property real scale: 0.5
                }
            }

            property JsonObject modes: JsonObject {
                property bool enable: true
                // Loads the Modes & Routines app (named from when it was an overlay).
                property bool overlayEnabled: true
                // Presets are added once; deleting one afterwards sticks.
                property bool presetsSeeded: false
                // "auto" shows the start/end banner in the island or, without
                // a notch, as a top-centre popup; "off" shows nothing.
                property string flash: "auto"
                property bool lockPill: true
                // Last visited page; unknown keys fall back to Modes.
                property string lastTab: "modes"
                property string lastModeId: ""
                property string lastRoutineId: ""
                // Seconds an auto-started mode's triggers must stay false
                // before it ends, so a workspace switch does not flap it.
                property int graceSec: 5
                // Mode definitions, in priority order (first wins among
                // automatic starts). Shape: see services/modes/ModeSchema.js.
                property list<var> modes: []
                property list<var> routines: []
                // Game detection (services/GameDetector.qml). Signals 1–3 are
                // instant; the GPU heuristic needs `gpuThreshold` % for `holdSec`.
                property JsonObject game: JsonObject {
                    property bool useLauncherClasses: true
                    property bool useDesktopCategory: true
                    property bool useGpuHeuristic: true
                    property int gpuThreshold: 45
                    property int holdSec: 20
                    property list<string> extraClasses: []
                }
            }

            // Alt+Tab. Drawn on the Dynamic Island when it is on, as a floating panel otherwise.
            property JsonObject windowSwitcher: JsonObject {
                property bool enable: true
                // Windows on every workspace (special ones included), or only those on screen.
                property bool includeOtherWorkspaces: true
                // Only the windows on the monitor Alt+Tab is pressed on.
                property bool currentMonitorOnly: false
                // Live window previews on the island's cover flow and the floating panel.
                property bool showThumbnails: true
                // Holding one selection this long peeks at the window where it is; 0 never peeks.
                property int peekDelayMs: 600
                // The peek shows the window's whole workspace (its other windows, the bar kept),
                // not the window alone over the wallpaper.
                property bool peekWholeWorkspace: false
                // A one-line key reminder under the switcher.
                property bool showKeyHints: true
                // Alt+letter on the desktop opens the switcher already searching. Off: typing
                // searches only once Alt+Tab has opened it.
                property bool searchAnywhere: false
            }

            property JsonObject overview: JsonObject {
                property bool enable: true
                property string style: "default"
                property real scale: 0.18 // Relative to screen size
                property real rows: 2
                property real columns: 5
                property bool orderRightLeft: false
                property bool orderBottomUp: false
                property bool centerIcons: true
            }

            property JsonObject regionSelector: JsonObject {
                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: false
                    property bool content: true
                    property bool showLabel: false
                    property real opacity: 0.3
                    property real contentRegionOpacity: 0.8
                    property int selectionPadding: 5
                }
                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                }
                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                    property int padding: 10
                }
                property JsonObject annotation: JsonObject {
                    property bool useSatty: false
                }
            }

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
                property int historyLength: 60
            }

            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true // Makes the below a whitelist for the tray and blacklist for the pinned area
                property list<var> pinnedItems: [ "Fcitx" ]
                property bool filterPassive: true
            }

            property JsonObject musicRecognition: JsonObject {
                property int timeout: 16
                property int interval: 4
            }

            property JsonObject search: JsonObject {
                property bool enableSystemControls: true
                property bool enableMathPreview: true
                property JsonObject appearance: JsonObject {
                    property bool accentPanels: true
                    property real accentStrength: 0.12
                    property bool showKeyHints: true
                    property bool showKeyHintBar: true
                    property int panelWidth: 860
                    property int panelBodyHeight: 420
                }
                property JsonObject clipboard: JsonObject {
                    property int panelWidth: 860
                    property real listColumnRatio: 0.40
                    property bool showMetadata: true
                    property int imageHeight: 200
                    property int previewFontSize: 12
                    property bool enableSloppySearch: false
                }
                property JsonObject fileBrowser: JsonObject {
                    property int panelWidth: 1120
                }
                property JsonObject fileContent: JsonObject {
                    property int maxResults: 40
                    property int maxFileSizeMb: 8
                    property int minimumQueryLength: 3
                }
                property JsonObject suggestions: JsonObject {
                    property bool enable: false
                    property int maxSuggestionsPerSection: 5
                }
                property bool showSettings: false
                property bool alwaysListApps: false
                property bool levenshtein: false
                property bool frecency: true
                property real fuzzyThreshold: 0.35
                property real fuzzyRelativeCutoff: 0.35
                property list<var> aliases: []
                property int nonAppResultDelay: 30 // This prevents lagging when typing
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com", "facebook.com"]
                property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
                property JsonObject modules: JsonObject {
                    property bool clipboard: true
                    property bool bluetooth: true
                    property bool translator: true
                    property bool mediaDownloader: true
                    property bool materialSymbols: true
                    property bool typingTest: true
                    property bool speedTest: true
                    property bool grammar: true
                    property bool commands: true
                    property bool emoji: true
                    property JsonObject emojis: JsonObject {
                        property bool enable: true
                        property string skinTone: "none"
                        property int gridColumns: 8
                        property bool showRecents: true
                        property string defaultCategory: "all"
                    }
                    property bool fileBrowser: true
                    property bool fonts: true
                    property bool gifs: true
                    property bool screenshots: true
                    property bool tasks: true
                    property bool timers: true
                    property bool tools: true
                    property bool windowManagement: true
                    property JsonObject settingsToggles: JsonObject {
                        property bool enable: true
                        property bool showPages: true
                        property int maxInlineResults: 0
                    }
                }
                property JsonObject speedTest: JsonObject {
                    property int duration: 10
                    property string mode: "both"
                    property string unit: "mbps"
                }
                property JsonObject ai: JsonObject {
                    property string trigger: "suggest"
                }
                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string emojis: ":"
                    property string keybinds: "<"
                    property string symbols: "."
                    property string math: "="
                    property string shellCommand: "$"
                    property string webSearch: "?"
                }
                property JsonObject imageSearch: JsonObject {
                    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
                    property bool useCircleSelection: false
                }
            }

            property JsonObject mediaDownloader: JsonObject {
                property bool enabled: true
                property string downloadPath: FileUtils.trimFileProtocol(`${Directories.home}/Downloads`)
                property int maxConcurrent: 2
                property string defaultFormat: "best"
                property bool embedMetadata: true
            }

            property JsonObject sidebar: JsonObject {
                property bool banner: true
                property bool bottomGroup: true
                property bool mediaPlayer: false
                property string bannerImage: ""
                property bool keepRightSidebarLoaded: true
                property JsonObject translator: JsonObject {
                    property bool enable: false
                    property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
                }
                property JsonObject media: JsonObject {
                    property bool enable: true
                    property bool artColors: false
                    property string artShape: "Oval"
                    property bool showLyrics: true
                    property bool shapeArt: false
                    property bool blurredBackground: false
                }
                
                property JsonObject ai: JsonObject {
                    property bool textFadeIn: false
                }
                property JsonObject booru: JsonObject {
                    property bool allowNsfw: false
                    property string defaultProvider: "yandere"
                    property int limit: 20
                    property JsonObject zerochan: JsonObject {
                        property string username: "[unset]"
                    }
                }
                property JsonObject cornerOpen: JsonObject {
                    property bool enable: true
                    property bool bottom: false
                    property bool valueScroll: true
                    property bool clickless: false
                    property int cornerRegionWidth: 250
                    property int cornerRegionHeight: 5
                    property string bottomLeftAction: "sidebarLeftOpen"
                    property string bottomRightAction: "sidebarRightOpen"
                    property bool visualize: false
                    property bool clicklessCornerEnd: true
                    property int clicklessCornerVerticalOffset: 1
                }

                property JsonObject quickToggles: JsonObject {
                    property string style: "android" // Options: classic, android
                    property JsonObject android: JsonObject {
                        property int columns: 5
                        property list<var> toggles: [
                            { "size": 2, "type": "network" },
                            { "size": 2, "type": "bluetooth"  },
                            { "size": 1, "type": "idleInhibitor" },
                            { "size": 1, "type": "mic" },
                            { "size": 2, "type": "audio" },
                            { "size": 2, "type": "nightLight" }
                        ]
                    }
                }

                property JsonObject quickSliders: JsonObject {
                    property bool enable: true
                    property bool showMic: false
                    property bool showVolume: true
                    property bool showBrightness: true
                }
            }

            property JsonObject custom: JsonObject {
                property string distroIcon: "spark"
                property bool colorizeIcon: true
            }

            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos.replace("file://","") // strip "file://"
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: "" // only copy to clipboard when empty
            }

            property JsonObject sounds: JsonObject {
                property bool battery: false
                property bool pomodoro: false
                property string theme: "freedesktop"
            }

            property JsonObject time: JsonObject {
                // https://doc.qt.io/qt-6/qtime.html#toString
                property string format: "hh:mm"
                property bool showDate: true
                property string shortDateFormat: "dd/MM"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
                property bool secondPrecision: false
            }

            property JsonObject updates: JsonObject {
                property bool enableCheck: true
                property int checkInterval: 120 // minutes
                property int adviseUpdateThreshold: 75 // packages
                property int stronglyAdviseUpdateThreshold: 200 // packages
            }
            
            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
                property bool showBlurBackground: false
                property bool showHomePath: true
                property string userPath: "" // This can be set to any path and it will show up as a quick access in the wallpaper selector"
                property string liveWallpapersPath: ""
                property bool showSearchbar: true
                property int columns: 4
                property bool closeAfterSelection: true
                property int changeInterval: 0 
                property string sortMode: "custom"
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true // Client-side decoration for shell apps
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20 // milliseconds
            }

            property JsonObject workSafety: JsonObject {
                property JsonObject enable: JsonObject {
                    property bool wallpaper: false
                    property bool clipboard: false
                }
                property JsonObject triggerCondition: JsonObject {
                    property list<string> networkNameKeywords: ["airport", "cafe", "college", "company", "eduroam", "free", "guest", "public", "school", "university"]
                    property list<string> fileKeywords: ["anime", "booru", "ecchi", "hentai", "yande.re", "konachan", "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"]
                    property list<string> linkKeywords: ["hentai", "porn", "sukebei", "hitomi.la", "rule34", "gelbooru", "fanbox", "dlsite"]
                }
            }
        }
    }
}
