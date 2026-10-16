import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas

AbstractWidget {
    id: root

    required property string configEntryName
    property int screenWidth: 1920
    property int screenHeight: 1080
    property int scaledScreenWidth: screenWidth
    property int scaledScreenHeight: screenHeight
    property real wallpaperScale: 1
    readonly property real renderScale: root.scale
    readonly property bool _resizeActive: root.dragging

    property Item wallpaperItem: null
    property bool paused: false
    property bool live: root.visible && root.opacity > 0 && !root.paused
    property string editInstanceId: ""
    property string instanceId: ""
    property string editWidgetId: ""
    readonly property string resolvedInstanceId: editInstanceId || instanceId || ""
    readonly property string editKey: resolvedInstanceId || configEntryName
    function selectForEditing() {
        GlobalStates.selectEditWidget(root.editKey, root.resolvedInstanceId, root.editWidgetId || root.configEntryName);
    }

    property real resizeMaxScale: 2
    property string lockBehavior: "keep"
    property real padding: 0
    property real dateSpacing: 0
    property bool isPreview: false
    property bool visibleWhenLocked: Config.options.lock.showWidgets
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    property real targetX: Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width))
    property real targetY : Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height))
    property real targetZ: configEntry.z
    x: targetX
    y: targetY
    z: targetZ
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    draggable: placementStrategy === "free" && !Config.options.background.widgetsLocked && !GlobalStates.screenLocked && !(configEntry?.pinned ?? false) && !Config.options.background.pinnedWidgets.includes(configEntryName)
    function restoreXYBinding() {
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
        root.z = Qt.binding(() => root.targetZ);
    }

    function commitPosition() {
        const newX = Math.max(0, Math.min(root.x, root.scaledScreenWidth - root.width));
        const newY = Math.max(0, Math.min(root.y, root.scaledScreenHeight - root.height));
        const currentInstId = root.resolvedInstanceId;
        if (currentInstId) {
            const instanceId = currentInstId;
            const newZ = root.z;
            // Replacing the model synchronously destroys the delegate. Finish
            // the release handlers first; the replacement restores its bindings.
            Qt.callLater(() => {
                Config.options.background.activeWidgets = Config.options.background.activeWidgets.map(entry =>
                    entry.id === instanceId ? Object.assign({}, entry, { x: newX, y: newY, z: newZ }) : entry);
            });
            return;
        } else {
            configEntry.x = newX;
            configEntry.y = newY;
            configEntry.z = root.z;
        }
        root.targetX = Qt.binding(() => Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width)));
        root.targetY = Qt.binding(() => Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height)));
        root.targetZ = Qt.binding(() => configEntry.z);
        root.restoreXYBinding();
    }

    onReleased: root.commitPosition()

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        const adaptiveColor = ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        return onNormalBackground ? Appearance.colors.colOnLayer0 : adaptiveColor;
    }

    property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    
    onWallpaperPathChanged: refreshPlacementIfNeeded()
    onPlacementStrategyChanged: refreshPlacementIfNeeded()
    Connections {
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;
        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
    }
    Process {
        id: leastBusyRegionProc
        property string wallpaperPath: root.wallpaperPath
        // TODO: make these less arbitrary
        property int contentWidth: 300
        property int contentHeight: 300
        property int horizontalPadding: 200
        property int verticalPadding: 200
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh")
            , "--screen-width", Math.round(root.scaledScreenWidth)
            , "--screen-height", Math.round(root.scaledScreenHeight)
            , "--width", contentWidth
            , "--height", contentHeight
            , "--horizontal-padding", horizontalPadding
            , "--vertical-padding", verticalPadding
            , wallpaperPath
            , ...(root.placementStrategy === "mostBusy" ? ["--busiest"] : [])
        ]
        stdout: StdioCollector {
            id: leastBusyRegionOutputCollector
            onStreamFinished: {
                const output = leastBusyRegionOutputCollector.text;
                if (output.length === 0) return;
                const parsedContent = JSON.parse(output);
                root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
                if (root.placementStrategy === "free") return;
                root.targetX = parsedContent.center_x * root.wallpaperScale - root.width / 2;
                root.targetY  = parsedContent.center_y * root.wallpaperScale - root.height / 2;
            }
        }
    }
}