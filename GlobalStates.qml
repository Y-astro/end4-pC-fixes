import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    signal requestBluetoothDialog()
    property bool presetBarHidden: false
    property bool presetRecoloring: false
    property bool presetHoldMotion: false
    property bool presetWorkDeferred: false
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool equalizerOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool mediaHovered: false
    property bool mediaDropdownHovered: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    // Policies & Phone Sidebar Integration
    property rect policiesPointerHole: Qt.rect(0, 0, 0, 0)
    property string policiesSurfaceNamespace: "quickshell:sidebarLeft"
    property string policiesSurfaceScreen: ""
    property int policiesHoldOpen: 0
    property bool policiesPinned: false
    property bool policiesDetached: false
    property string policiesRequestTabIcon: ""
    property string phoneRequestSubPage: ""
    property bool settingsOpen: false
    property bool settingsSuspendedForScreenshot: false
    property int settingsPendingPage: -1
    property string settingsPendingSubPage: ""
    property string settingsPendingPageName: ""
    property string settingsPendingSection: ""
    property int settingsNavigationRequest: 0
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool overviewUsesAppDrawer: false
    property bool appDrawerOpen: false
    property string appDrawerQuery: ""
    property string activeSearchMonitor: ""
    property string activeSearchQuery: ""
    property bool searchPanelActive: false
    property bool panelOpenedDirectly: false
    property string searchTargetWindowAddress: ""
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
    property bool cheatsheetOpen: false
    property bool notesAppOpen: false
    property bool clockAppOpen: false
    property bool usageOpen: false
    property bool modesOpen: false
    property bool editMode: false
    property bool islandDashboardOpen: false

    function captureSearchTargetWindow(): void {
        let rawAddress = String(ToplevelManager?.activeToplevel?.HyprlandToplevel?.address ?? "").trim();
        if (rawAddress.length === 0) {
            const workspaceId = Number(HyprlandData?.activeWorkspace?.id ?? -1);
            const candidates = Array.from(HyprlandData?.windowList ?? [])
                .filter(window => Number(window?.workspace?.id ?? -2) === workspaceId)
                .sort((left, right) => Number(left?.focusHistoryID ?? 9999) - Number(right?.focusHistoryID ?? 9999));
            rawAddress = String(candidates[0]?.address ?? "").trim();
        }
        root.searchTargetWindowAddress = rawAddress;
    }

    function toggleOverview(monitorName) {
        if (root.overviewOpen) {
            root.closeOverview();
        } else {
            root.openOverview(monitorName);
        }
    }

    function openOverview(monitorName) {
        root.captureSearchTargetWindow();
        root.activeSearchMonitor = monitorName || Hyprland.focusedMonitor?.name || "";
        root.overviewOpen = true;
    }

    function closeOverview() {
        root.overviewOpen = false;
        root.activeSearchMonitor = "";
    }

    function closeSearchSurfaces() {
        root.closeOverview();
    }

    function toggleClassicOverview(monitorName) {
        root.toggleOverview(monitorName);
    }

    function openClassicOverview(monitorName) {
        root.openOverview(monitorName);
    }

    property string searchPendingPanel: ""
    property string searchPendingPanelQuery: ""
    property int searchPanelNavigationRequest: 0

    function openSearchPanel(panelId, monitorName, initialQuery) {
        const requested = String(panelId ?? "").trim();
        if (requested.length === 0)
            return;
        root.searchPendingPanel = requested;
        root.searchPendingPanelQuery = String(initialQuery ?? "");
        root.searchPanelNavigationRequest++;
        root.panelOpenedDirectly = true;
        root.openOverview(monitorName);
    }

    function consumePendingSearchPanel() {
        const pending = root.searchPendingPanel;
        root.searchPendingPanel = "";
        return pending;
    }

    function consumePendingSearchPanelQuery() {
        const pending = root.searchPendingPanelQuery;
        root.searchPendingPanelQuery = "";
        return pending;
    }

    property var overviewBackgroundControllers: ({})

    function registerOverviewBackgroundController(screenName, controller) {
        if (!screenName || !controller)
            return;
        const next = ({});
        for (const key in root.overviewBackgroundControllers)
            next[key] = root.overviewBackgroundControllers[key];
        next[screenName] = controller;
        root.overviewBackgroundControllers = next;
    }

    function unregisterOverviewBackgroundController(screenName, controller) {
        if (!screenName || root.overviewBackgroundControllers[screenName] !== controller)
            return;
        const next = ({});
        for (const key in root.overviewBackgroundControllers) {
            if (key !== screenName)
                next[key] = root.overviewBackgroundControllers[key];
        }
        root.overviewBackgroundControllers = next;
    }

    function overviewBackgroundControllerFor(screenName) {
        return root.overviewBackgroundControllers[screenName] ?? null;
    }
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
    property string osdIndicatorType: "volume"
    property bool barCenterOnly: false
    property bool diSessionOpen: false

    readonly property bool dynamicIslandEnabled: Config.options.bar.layouts.leftLayout.includes("dynamicIsland")
        || Config.options.bar.layouts.middleLayout.includes("dynamicIsland")
        || Config.options.bar.layouts.rightLayout.includes("dynamicIsland")

    // Media Mode State Management
    property int mediaModeCount: 0
    readonly property bool mediaModeActive: mediaModeCount > 0
    property var mediaModeMonitors: []
    property int mediaModeCloseAllTrigger: 0
    property int mediaModeRequestSerial: 0
    property string mediaModeRequestedAction: ""
    property bool mediaModeImmersiveOptionsOpen: false

    onMediaModeCloseAllTriggerChanged: {
        root.mediaModeMonitors = [];
        root.mediaModeCount = 0;
    }

    onMediaModeRequestSerialChanged: {
        const screens = Quickshell.screens;
        const targetScreen = Hyprland.focusedMonitor?.name || (screens.length > 0 ? screens[0].name : "");
        if (root.mediaModeRequestedAction === "open") {
            root.setMediaModeActiveForScreen(targetScreen, true);
        } else if (root.mediaModeRequestedAction === "close") {
            if (Config.options.background.mediaMode.togglePerMonitor) {
                root.setMediaModeActiveForScreen(targetScreen, false);
            } else {
                root.mediaModeMonitors = [];
                root.mediaModeCount = 0;
            }
        } else if (root.mediaModeRequestedAction === "toggle") {
            const currentlyActive = root.isMediaModeActiveForScreen(targetScreen);
            if (Config.options.background.mediaMode.togglePerMonitor) {
                root.setMediaModeActiveForScreen(targetScreen, !currentlyActive);
            } else {
                if (currentlyActive) {
                    root.mediaModeMonitors = [];
                    root.mediaModeCount = 0;
                } else {
                    for (let i = 0; i < screens.length; i++) {
                        root.setMediaModeActiveForScreen(screens[i].name, true);
                    }
                }
            }
        }
    }

    function requestMediaMode(action = "toggle") {
        if (action !== "toggle" && action !== "open" && action !== "close")
            return;
        root.mediaModeRequestedAction = action;
        root.mediaModeRequestSerial++;
    }

    function setMediaModeActiveForScreen(screenName, active) {
        if (!screenName) return;
        var list = mediaModeMonitors.slice();
        var index = list.indexOf(screenName);
        if (active && index === -1) {
            list.push(screenName);
        } else if (!active && index !== -1) {
            list.splice(index, 1);
        }
        mediaModeMonitors = list;
        mediaModeCount = mediaModeMonitors.length;
    }

    function isMediaModeActiveForScreen(screenName) {
        if (!(Config.options?.background?.mediaMode?.togglePerMonitor ?? false)) {
            return mediaModeActive;
        }
        if (!screenName) return false;
        return mediaModeMonitors.includes(screenName);
    }

    function openSettingsPage(pageId, subPageId, sectionId) {
        const targetSubPage = subPageId || "";
        const targetSection = sectionId || "";
        if (!pageId || pageId === "") {
            root.settingsPendingPageName = "";
            root.settingsPendingSubPage = targetSubPage;
            root.settingsPendingSection = targetSection;
            root.settingsOpen = true;
            return;
        }

        if (SettingsPageRegistry.pageIndexById(pageId) < 0)
            return;

        root.settingsPendingPageName = pageId;
        root.settingsPendingSubPage = targetSubPage;
        root.settingsPendingSection = targetSection;
        root.settingsNavigationRequest += 1;
        root.settingsOpen = true;
    }

    function consumePendingSettingsPage() {
        const pending = root.settingsPendingPageName;
        root.settingsPendingPageName = "";
        return pending;
    }

    function toggleLeftSidebar(monitorName) {
        root.sidebarLeftOpen = !root.sidebarLeftOpen;
    }

    function toggleRightSidebar(monitorName) {
        root.sidebarRightOpen = !root.sidebarRightOpen;
    }

    function requestBarPlacement(bottom, vertical) {
        if (!Config.ready)
            return false;
        if (Config.options.bar.bottom === bottom && Config.options.bar.vertical === vertical)
            return false;
        Config.options.bar.bottom = bottom;
        Config.options.bar.vertical = vertical;
        return true;
    }

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
        id: mediaControlsCloseTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (!root.mediaHovered && !root.mediaDropdownHovered && !root.equalizerOpen && !Config.options?.bar?.media?.alwaysVisible) {
                root.mediaControlsOpen = false;
            }
        }
    }

    function checkMediaControlsHover() {
        if (root.mediaHovered || root.mediaDropdownHovered) {
            mediaControlsCloseTimer.stop();
            if (!root.mediaControlsOpen) {
                root.mediaControlsOpen = true;
            }
        } else {
            if (root.mediaControlsOpen) {
                mediaControlsCloseTimer.restart();
            }
        }
    }

    onMediaControlsOpenChanged: {
        if (!mediaControlsOpen) {
            mediaControlsCloseTimer.stop();
            mediaDropdownHovered = false;
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

    function toggleSettings(): void {
        root.settingsOpen = !root.settingsOpen;
    }
    function openSettings(): void {
        root.settingsOpen = true;
    }
    function closeSettings(): void {
        root.settingsOpen = false;
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.toggleSettings();
        }

        function open(): void {
            root.openSettings();
        }

        function close(): void {
            root.closeSettings();
        }

        function openPage(pageId: string): void {
            root.openSettingsPage(pageId);
        }

        function openSection(pageId: string, sectionTitle: string): void {
            root.openSettingsPage(pageId, "", sectionTitle);
        }

        function openSubPage(pageId: string, subPage: string): void {
            root.openSettingsPage(pageId, subPage || "");
        }
    }

    CompositorGlobalShortcut {
        name: "settingsOpen"
        description: "Opens settings on press"
        onPressed: {
            root.openSettings();
        }
    }

    CompositorGlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings on press"
        onPressed: {
            root.toggleSettings();
        }
    }

    IpcHandler {
        target: "mediaMode"

        function toggle(): void {
            root.requestMediaMode("toggle");
        }

        function open(): void {
            root.requestMediaMode("open");
        }

        function close(): void {
            root.requestMediaMode("close");
        }

        function setImmersiveLayout(layout: string): void {
            Persistent.states.background.mediaMode.immersiveArtLayout = layout === "cover" ? "cover" : "side";
        }

        function setPanelsVisible(visible: bool): void {
            Persistent.states.background.mediaMode.coverExpanded = !visible;
        }

        function setImmersiveOptionsOpen(open: bool): void {
            root.mediaModeImmersiveOptionsOpen = open;
        }
    }

    CompositorGlobalShortcut {
        name: "mediaModeToggle"
        description: "Toggles Media Mode on press"
        onPressed: {
            root.requestMediaMode("toggle");
        }
    }
}
