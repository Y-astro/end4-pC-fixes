pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.modules.ii.background.widgets

// Additive adapter for registry instances. Legacy singleton widgets keep their
// existing loader and settings; only explicit activeWidgets entries arrive here.
Item {
    id: root
    required property var instance
    required property var screen
    property var wallpaperItem: null
    property bool wallpaperSafetyTriggered: false

    readonly property var placement: ({
        x: Number(root.instance.x ?? 200),
        y: Number(root.instance.y ?? 200),
        z: Number(root.instance.z ?? 0),
        pinned: root.instance.pinned === true,
        placementStrategy: root.instance.placementStrategy ?? "free"
    })
    readonly property bool onMonitor: !root.instance.monitorName || root.instance.monitorName === root.screen.name
    readonly property string sourceUrl: String(WidgetsRegistry.getQmlPath(root.instance.widgetId))

    Loader {
        id: widgetLoader
        active: root.onMonitor && root.sourceUrl.length > 0
        function loadWidget() {
            if (!active)
                return;
            setSource(root.sourceUrl, {
                screenWidth: Qt.binding(() => root.screen.width),
                screenHeight: Qt.binding(() => root.screen.height),
                scaledScreenWidth: Qt.binding(() => root.screen.width),
                scaledScreenHeight: Qt.binding(() => root.screen.height),
                wallpaperScale: 1,
                wallpaperItem: Qt.binding(() => root.wallpaperItem),
                configEntry: Qt.binding(() => root.placement),
                editInstanceId: Qt.binding(() => String(root.instance.id ?? root.instance.instanceId ?? "")),
                editWidgetId: Qt.binding(() => String(root.instance.widgetId)),
                lockBehavior: Qt.binding(() => root.instance.lockBehavior ?? "keep")
            });
        }
        Component.onCompleted: loadWidget()
        onActiveChanged: loadWidget()
        Connections {
            target: root
            function onSourceUrlChanged() { widgetLoader.loadWidget(); }
        }
    }
}
