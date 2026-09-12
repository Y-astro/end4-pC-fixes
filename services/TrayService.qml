pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    property int updateTrigger: 0
    property bool smartTray: Config.options.tray.filterPassive
    property list<var> itemsInUserList: {
        updateTrigger;
        return SystemTray.items.values.filter(i => (Config.options.tray.pinnedItems.includes(i.id) && (!smartTray || i.status !== Status.Passive)))
    }
    property list<var> itemsNotInUserList: {
        updateTrigger;
        return SystemTray.items.values.filter(i => (!Config.options.tray.pinnedItems.includes(i.id) && (!smartTray || i.status !== Status.Passive)))
    }

    property bool invertPins: Config.options.tray.invertPinnedItems
    property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
    property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList
    readonly property bool hasItems: pinnedItems.length > 0 || unpinnedItems.length > 0

    Instantiator {
        model: SystemTray.items
        Connections {
            required property var modelData
            target: modelData
            function onStatusChanged() {
                root.updateTrigger++
            }
        }
    }

    function getTooltipForItem(item) {
        var result = item.tooltipTitle.length > 0 ? item.tooltipTitle
                : (item.title.length > 0 ? item.title : item.id);
        if (item.tooltipDescription.length > 0) result += " • " + item.tooltipDescription;
        if (Config.options.tray.showItemId) result += "\n[" + item.id + "]";
        return result;
    }

    // Pinning
    function pin(itemId) {
        var pins = Config.options.tray.pinnedItems;
        if (pins.includes(itemId)) return;
        Config.options.tray.pinnedItems.push(itemId);
    }
    function unpin(itemId) {
        Config.options.tray.pinnedItems = Config.options.tray.pinnedItems.filter(id => id !== itemId);
    }
    function isPinned(itemId) {
        for (var i = 0; i < root.pinnedItems.length; i++) {
            if (root.pinnedItems[i].id === itemId)
                return true;
        }
        return false;
    }

    function togglePin(itemId) {
        var pins = Config.options.tray.pinnedItems;
        if (pins.includes(itemId)) {
            unpin(itemId)
        } else {
            pin(itemId)
        }
    }

}
