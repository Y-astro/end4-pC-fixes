import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: false
    property string menuId: "desktop"
    property string editingId: ""
    readonly property var layout: ContextMenus.layoutFor(root.menuId)
    readonly property var definitions: (ContextMenus.definition(root.menuId)?.entries ?? []).concat(ContextMenus.customEntriesFor(root.menuId))
    readonly property var entries: root.layout.order.map(id => root.definitions.find(e => e.id === id)).filter(Boolean)
    function change(id, field) {
        const next = ContextMenus.layoutFor(root.menuId);
        next[field] = next[field].includes(id) ? next[field].filter(x => x !== id) : next[field].concat([id]);
        ContextMenus.setLayout(root.menuId, next);
    }
    function move(id, direction) {
        const next = ContextMenus.layoutFor(root.menuId);
        const at = next.order.indexOf(id), to = at + direction;
        if (at < 0 || to < 0 || to >= next.order.length) return;
        next.order.splice(at, 1); next.order.splice(to, 0, id);
        ContextMenus.setLayout(root.menuId, next);
    }
    ContentSection {
        title: qsTr("Context menus"); icon: "touch_app"
        ConfigComboBox {
            text: qsTr("Menu")
            model: ContextMenus.menus.map(menu => ({ displayName: menu.name, value: menu.id }))
            currentValue: root.menuId
            onSelected: value => { root.menuId = value; root.editingId = ""; }
        }
        ConfigComboBox {
            text: qsTr("Style")
            model: [{ value: "comfortable", displayName: qsTr("Comfortable") }, { value: "compact", displayName: qsTr("Compact") }]
            currentValue: Config.options.contextMenu.style
            onSelected: value => Config.options.contextMenu.style = value
        }
        ConfigComboBox {
            text: qsTr("Submenus")
            model: [{ value: "inline", displayName: qsTr("Inside the menu") }, { value: "cascade", displayName: qsTr("Beside the menu") }]
            currentValue: Config.options.contextMenu.submenus
            onSelected: value => Config.options.contextMenu.submenus = value
        }
        ConfigSlider {
            text: qsTr("Menu size"); buttonIcon: "zoom_in"
            from: 0.5; to: 2; stepSize: 0.05; value: Config.options.contextMenu.scale
            onValueChanged: if (value !== Config.options.contextMenu.scale) Config.options.contextMenu.scale = value
        }
        NoticeBox {
            Layout.fillWidth: true; materialIcon: "info"
            text: qsTr("Use the arrows to reorder entries. The eye hides an entry; the star puts it in the icon row in Compact style. Custom commands receive the clicked item as $II_CONTEXT_TARGET.")
        }
        Repeater {
            model: root.entries
            delegate: RowLayout {
                id: entryRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                opacity: root.layout.hidden.includes(modelData.id) ? 0.5 : 1
                MaterialSymbol { text: modelData.symbol || "horizontal_rule"; iconSize: 20 }
                StyledText { Layout.fillWidth: true; text: entryRow.modelData.title || qsTr("Separator"); elide: Text.ElideRight }
                IconToolbarButton { text: "arrow_upward"; enabled: entryRow.index > 0; onClicked: root.move(entryRow.modelData.id, -1) }
                IconToolbarButton { text: "arrow_downward"; enabled: entryRow.index < root.entries.length - 1; onClicked: root.move(entryRow.modelData.id, 1) }
                IconToolbarButton { text: root.layout.hidden.includes(entryRow.modelData.id) ? "visibility_off" : "visibility"; onClicked: root.change(entryRow.modelData.id, "hidden") }
                IconToolbarButton { visible: !entryRow.modelData.header && !entryRow.modelData.separator; text: root.layout.bar.includes(entryRow.modelData.id) ? "star" : "star_outline"; onClicked: root.change(entryRow.modelData.id, "bar") }
                IconToolbarButton {
                    visible: !!entryRow.modelData.command; text: "edit"
                    onClicked: { root.editingId = entryRow.modelData.id; customTitle.inputText = entryRow.modelData.title; customIcon.inputText = entryRow.modelData.symbol; customCommand.inputText = entryRow.modelData.command; }
                }
                IconToolbarButton { visible: !!entryRow.modelData.command; text: "delete"; onClicked: ContextMenus.removeCustom(entryRow.modelData.id) }
            }
        }
        RippleButton {
            Layout.fillWidth: true; implicitHeight: 40
            onClicked: ContextMenus.resetLayout(root.menuId)
            StyledText { anchors.centerIn: parent; text: qsTr("Reset this menu") }
        }
    }
    ContentSection {
        title: root.editingId ? qsTr("Edit custom action") : qsTr("Add custom action"); icon: "terminal"
        ConfigTextField { id: customTitle; text: qsTr("Title"); icon: "label" }
        ConfigTextField { id: customIcon; text: qsTr("Material symbol"); icon: "image"; inputText: "terminal" }
        ConfigTextField { id: customCommand; text: qsTr("Command"); icon: "terminal" }
        RowLayout {
            RippleButton {
                Layout.fillWidth: true; implicitHeight: 40
                enabled: !!customTitle.inputText.trim() && !!customCommand.inputText.trim()
                onClicked: {
                    if (root.editingId) ContextMenus.updateCustom(root.editingId, customIcon.inputText, customTitle.inputText, customCommand.inputText);
                    else ContextMenus.addCustom(root.menuId, customIcon.inputText, customTitle.inputText, customCommand.inputText);
                    root.editingId = ""; customTitle.inputText = ""; customCommand.inputText = "";
                }
                StyledText { anchors.centerIn: parent; text: root.editingId ? qsTr("Save action") : qsTr("Add action") }
            }
            RippleButton {
                visible: !!root.editingId; implicitWidth: 80; implicitHeight: 40
                onClicked: { root.editingId = ""; customTitle.inputText = ""; customCommand.inputText = ""; }
                StyledText { anchors.centerIn: parent; text: qsTr("Cancel") }
            }
        }
    }
}
