import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    signal requestBluetoothDialog()
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool equalizerOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool settingsOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false
    property string settingsPage: ""
    property Item currentPageInstance: null
    property list<real> visualizerPoints: []
    property bool desktopWidgetKeyboardFocus: false
    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0
    property string wallpaperSelectorTarget: "wallpaper"
    property bool dropShelfOpen: false
    property real dropShelfX: 0
    property real dropShelfY: 0

    // Radial menu state
    property bool radialMenuOpen: false
    property var  radialMenuScreen: null
    property real radialMenuX: 0
    property real radialMenuY: 0
    property var  radialMenuContextWindow: ({})
    property var  radialMenuGpuProfile: null
    property var  browserTabsList: []
    property var  activeClientsList: []

    signal centeredWallpaperThumpRequested()

    // Shared by desktop (Background) and lock screen (LockSurface) scroll-to-cycle
    readonly property var centeredShapeOptions: [
        "Circle", "Square", "Slanted", "Arch", "Fan", "Arrow", "SemiCircle", "Oval", "Pill",
        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
        "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
        "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Boom", "SoftBoom", "Flower",
        "Puffy", "PuffyDiamond", "PixelCircle", "PixelTriangle", "Bun", "Heart"
    ]
    function cycleCenteredWallpaperShape(direction) {
        const opts = root.centeredShapeOptions
        const i = opts.indexOf(Config.options.background.centeredWallpaperShape)
        Config.options.background.centeredWallpaperShape = opts[(i + direction + opts.length) % opts.length]
    }

    readonly property var hotCornerOptions: [
        { displayName: Translation.tr("None"),                  value: "none" },
        { displayName: Translation.tr("Left Sidebar"),           value: "sidebarLeftOpen" },
        { displayName: Translation.tr("Right Sidebar"),          value: "sidebarRightOpen" },
        { displayName: Translation.tr("Overview Launcher"),               value: "overviewOpen" },
        { displayName: Translation.tr("Wallpaper Selector"),     value: "wallpaperSelectorOpen" },
        { displayName: Translation.tr("Media Controls"),         value: "mediaControlsOpen" },
        { displayName: Translation.tr("Overlay"),                value: "overlayOpen" },
        { displayName: Translation.tr("ScreenShot Region"),        value: "regionSelectorOpen" },
        { displayName: Translation.tr("Screen Translator"),      value: "screenTranslatorOpen" },
        { displayName: Translation.tr("On-screen Keyboard"),     value: "oskOpen" },
        { displayName: Translation.tr("Session Menu"),           value: "sessionOpen" }
    ]

    function toggleState(name) {
        if (!name || name === "none") return;
        root[name] = !root[name];
    }
    
    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    Timer {
        id: barRefreshTimer
        interval: 200
        repeat: false
        onTriggered: {
            root.barOpen = true
        }
    }

    function refreshBar() {
        if (!root.barOpen) return;
        root.barOpen = false
        barRefreshTimer.restart()
    }

    CompositorGlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"
        onPressed: { root.superDown = true }
        onReleased: { root.superDown = false }
    }

    IpcHandler {
        target: "background"
        function toggleCenteredWallpaper(): void {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }

     CompositorGlobalShortcut {
        name: "centeredWallpaperToggle"
        description: "Toggles centered wallpaper"
        onPressed: {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }


    // ── Radial menu: cursor-position + active window context reader ───────────
    Process {
        id: radialMenuCursorProc
        command: ["python3", `${Directories.configPath}/modules/ii/radialMenu/hypr_ipc.py`, "context"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim())
                    const pos = data.cursor || { x: 0, y: 0 }
                    let screen = null
                    for (let i = 0; i < Quickshell.screens.length; i++) {
                        const s = Quickshell.screens[i]
                        if (pos.x >= s.x && pos.x < s.x + s.width &&
                            pos.y >= s.y && pos.y < s.y + s.height) {
                            screen = s
                            break
                        }
                    }
                    if (!screen) {
                        const name = Hyprland.focusedMonitor?.name
                        screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
                    }
                    root.radialMenuContextWindow = data.window || {}
                    root.radialMenuGpuProfile = data.gpu || null
                    root.browserTabsList = data.tabs || []
                    root.activeClientsList = data.clients || []
                    root.radialMenuScreen = screen
                    root.radialMenuX = pos.x - screen.x
                    root.radialMenuY = pos.y - screen.y
                    root.radialMenuOpen = true
                } catch (e) {
                    console.warn("[RadialMenu] context/cursorpos parse failed:", e)
                }
            }
        }
    }

    // On-demand tab refresh process
    Process {
        id: refreshTabsProc
        command: ["python3", `${Directories.configPath}/modules/ii/radialMenu/get_browser_tabs.py`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.browserTabsList = JSON.parse(text.trim())
                } catch(e) {}
            }
        }
    }

    function refreshTabs() {
        refreshTabsProc.running = true
    }

    signal radialMenuCloseRequested()

    function requestCloseRadialMenu() {
        radialMenuCloseRequested()
    }

    CompositorGlobalShortcut {
        name: "radialMenu"
        description: "Open radial pie menu at cursor"
        onPressed: {
            if (root.radialMenuOpen) {
                root.requestCloseRadialMenu()
                return
            }
            radialMenuCursorProc.running = true
        }
    }
}
