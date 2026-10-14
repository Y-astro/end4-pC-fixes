import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    readonly property var components: [
        { id: "launcherButton", title: qsTr("Launcher"), icon: "search" },
        { id: "workspaces", title: qsTr("Workspaces"), icon: "workspaces" },
        { id: "activeWindow", title: qsTr("Active window"), icon: "label" },
        { id: "clockWidget", title: qsTr("Clock"), icon: "schedule" },
        { id: "sysTray", title: qsTr("System tray"), icon: "apps" },
        { id: "utilButtons", title: qsTr("Utilities"), icon: "build" },
        { id: "systemIcons", title: qsTr("System icons"), icon: "settings" },
        { id: "powerButton", title: qsTr("Power"), icon: "power_settings_new" },
        { id: "leftSidebarButton", title: qsTr("Policies"), icon: "shield" },
        { id: "media", title: qsTr("Media"), icon: "music_note" },
        { id: "resources", title: qsTr("Resources"), icon: "monitor_heart" },
        { id: "weatherBar", title: qsTr("Weather"), icon: "cloud" },
        { id: "bluetooth", title: qsTr("Bluetooth"), icon: "bluetooth" },
        { id: "batteryIndicator", title: qsTr("Battery"), icon: "battery_full" },
        { id: "hyprlandXkbIndicator", title: qsTr("Keyboard layout"), icon: "keyboard" },
        { id: "networkSpeed", title: qsTr("Network speed"), icon: "network_check" },
        { id: "updatesCount", title: qsTr("Updates"), icon: "update" },
        { id: "notificationUnreadCount", title: qsTr("Unread notifications"), icon: "notifications" },
        { id: "visualizer", title: qsTr("Visualizer"), icon: "graphic_eq" },
        { id: "dynamicIsland", title: qsTr("Dynamic Island"), icon: "radio_button_checked" },
        { id: "divisor", title: qsTr("Separator"), icon: "more_vert" }
    ]
    function info(id) { return root.components.find(c => c.id === id) || { id: id, title: id, icon: "widgets" }; }
    function entries(key) {
        const hidden = Config.options.bar.layouts.hiddenWidgets;
        return Config.options.bar.layouts[key].map(id => ({ id: id, visible: !hidden.includes(id) }));
    }
    function update(key, entries) {
        const oldIds = Config.options.bar.layouts[key];
        let hidden = Config.options.bar.layouts.hiddenWidgets.filter(id => !oldIds.includes(id));
        for (const entry of entries) if (!entry.visible && !hidden.includes(entry.id)) hidden.push(entry.id);
        Config.options.bar.layouts.hiddenWidgets = hidden;
        Config.options.bar.layouts[key] = entries.map(entry => entry.id);
    }
    ContentPage {
        anchors.fill: parent
        forceWidth: false
        NoticeBox {
            Layout.fillWidth: true
            materialIcon: "drag_indicator"
            text: qsTr("Drag rows to reorder. Hide or remove a component, then add it to another group to move it. Changes apply immediately.")
        }
        Repeater {
            model: [
                { key: "leftLayout", title: qsTr("Left / top") },
                { key: "middleLayout", title: qsTr("Centre") },
                { key: "rightLayout", title: qsTr("Right / bottom") }
            ]
            delegate: ContentSection {
                required property var modelData
                title: modelData.title
                icon: "view_stream"
                ConfigListView {
                    barSection: -1
                    listModel: root.entries(modelData.key)
                    infoProvider: root.info
                    normalizeEntry: entry => ({ id: entry.id, visible: entry.visible !== false })
                    availableComponents: root.components.filter(c => !Config.options.bar.layouts[modelData.key].includes(c.id))
                    onUpdated: entries => root.update(modelData.key, entries)
                }
            }
        }
    }
}
