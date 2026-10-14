pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: root
    readonly property string menuId: GlobalStates.desktopMenuId || "desktop"
    readonly property var instance: Config.options.background.activeWidgets?.find(entry => entry.id === GlobalStates.editWidgetInstanceId)
    readonly property var selectedEntry: GlobalStates.editWidgetInstanceId ? root.instance : Config.options.background.widgets[GlobalStates.editWidgetKey]
    readonly property var liveEntries: (ContextMenus.definition(root.menuId)?.entries ?? []).filter(entry => {
        if (entry.header) return false;
        if (root.menuId === "editWidget" && entry.id === "duplicate") return !!root.instance;
        return true;
    }).map(entry => Object.assign({}, entry, { checked: entry.id === "pin" && (root.instance ? !!root.instance.pinned : Config.options.background.pinnedWidgets.includes(GlobalStates.editWidgetKey)) }));
    readonly property var arranged: ContextMenus.arrange(root.menuId, root.liveEntries)
    function openCentered(shouldOpen) {
        if (!shouldOpen) { GlobalStates.desktopMenuOpen = false; return; }
        const screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        GlobalStates.desktopMenuId = "desktop";
        GlobalStates.desktopMenuScreen = screen;
        GlobalStates.desktopMenuX = screen.width / 2;
        GlobalStates.desktopMenuY = screen.height / 2;
        GlobalStates.desktopMenuOpen = true;
    }
    function activate(entry) {
        if (entry.id === "style") { menuLoader.item.submenuOpen = !menuLoader.item.submenuOpen; return; }
        GlobalStates.desktopMenuOpen = false;
        if (entry.custom) { ContextMenus.runCustom(entry, root.menuId === "editWidget" ? GlobalStates.editWidgetKey : Config.options.background.wallpaperPath); return; }
        if (root.menuId === "editWidget") {
            if (entry.id === "options") GlobalStates.editWidgetOptionsRequested();
            else if (entry.id === "remove") {
                if (root.instance) Config.options.background.activeWidgets = Config.options.background.activeWidgets.filter(e => e.id !== root.instance.id);
                else if (root.selectedEntry) root.selectedEntry.enable = false;
                GlobalStates.selectEditWidget("", "", "");
            } else if (entry.id === "duplicate" && root.instance) {
                const copy = Object.assign({}, root.instance, { id: root.instance.widgetId + "-" + Date.now().toString(36), x: root.instance.x + 24, y: root.instance.y + 24 });
                Config.options.background.activeWidgets = Config.options.background.activeWidgets.concat([copy]);
                GlobalStates.selectEditWidget(copy.id, copy.id, GlobalStates.editWidgetConfigName);
            } else if (entry.id === "pin") {
                if (root.instance) Config.options.background.activeWidgets = Config.options.background.activeWidgets.map(e => e.id === root.instance.id ? Object.assign({}, e, { pinned: !e.pinned }) : e);
                else {
                    const pinned = Config.options.background.pinnedWidgets;
                    const key = GlobalStates.editWidgetKey;
                    Config.options.background.pinnedWidgets = pinned.includes(key) ? pinned.filter(id => id !== key) : pinned.concat([key]);
                }
            }
            return;
        }
        switch (entry.id) {
        case "widgets": case "edit": GlobalStates.openEditMode(root.menuId === "bar" ? "bar" : "widgets", GlobalStates.desktopMenuScreen?.name); break;
        case "bar": GlobalStates.openEditMode("bar", GlobalStates.desktopMenuScreen?.name); break;
        case "dropShelf": GlobalStates.dropShelfX = GlobalStates.desktopMenuX; GlobalStates.dropShelfY = GlobalStates.desktopMenuY; GlobalStates.dropShelfOpen = true; break;
        case "liveWallpaper": Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode, Config.options.wallpaperSelector.liveWallpapersPath ?? ""); break;
        case "settings": GlobalStates.closeEditMode(); if (root.menuId === "bar") GlobalStates.openSettingsPage("bar"); else GlobalStates.settingsOpen = true; break;
        case "customize": GlobalStates.closeEditMode(); GlobalStates.openSettingsPage("contextMenu"); break;
        }
    }
    FolderListModel {
        id: wallpaperFolder
        folder: "file://" + Config.options.background.wallpaperPath.substring(0, Config.options.background.wallpaperPath.lastIndexOf("/"))
        showDirs: false; nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    }
    readonly property var carouselModel: {
        const path = Config.options.background.wallpaperPath;
        const list = [(/\.(mp4|webm|mkv|avi|mov)$/i.test(path) ? Config.options.background.thumbnailPath : path)];
        for (let i = 0; i < wallpaperFolder.count && list.length < 6; i++) {
            const file = FileUtils.trimFileProtocol(wallpaperFolder.get(i, "filePath").toString());
            if (!list.includes(file)) list.push(file);
        }
        return list.filter(Boolean);
    }
    Loader {
        id: menuLoader
        active: GlobalStates.desktopMenuOpen && !GlobalStates.screenLocked
        sourceComponent: PanelWindow {
            id: window
            screen: GlobalStates.desktopMenuScreen ?? Quickshell.screens[0]
            color: "transparent"; exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:desktopMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchors { top: true; bottom: true; left: true; right: true }
            property bool submenuOpen: false
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: GlobalStates.desktopMenuOpen = false }
            Item {
                id: cardSlot
                width: card.width * ContextMenus.scale
                height: Math.min(card.implicitHeight * ContextMenus.scale, window.height - 16)
                x: Math.max(8, Math.min(GlobalStates.desktopMenuX - width / 2, window.width - width - 8))
                y: Math.max(8, Math.min(GlobalStates.desktopMenuY - height / 2, window.height - height - 8))
                Rectangle {
                    id: card
                    width: Math.min(ContextMenus.compact ? 300 : 348, (window.width - 16) / ContextMenus.scale)
                    implicitHeight: contents.implicitHeight + 16
                    height: Math.min(implicitHeight, (window.height - 16) / ContextMenus.scale)
                    scale: ContextMenus.scale; transformOrigin: Item.TopLeft
                    radius: Appearance.rounding.large; color: Appearance.colors.colLayer0; clip: true
                    focus: true
                    Keys.onEscapePressed: GlobalStates.desktopMenuOpen = false
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: wheel => wheel.accepted = true }
                    Flickable {
                        anchors.fill: parent; anchors.margins: 8
                        contentHeight: contents.implicitHeight; clip: true
                        ColumnLayout {
                            id: contents
                            width: parent.width
                            spacing: 4
                            Rectangle {
                                Layout.fillWidth: true; implicitHeight: 140
                                visible: root.menuId === "desktop" && ContextMenus.isShown("desktop", "recents") && !window.submenuOpen
                                radius: Appearance.rounding.large; color: Appearance.colors.colLayer1; clip: true
                                Carousel {
                                    anchors.fill: parent; anchors.margins: 8
                                    model: root.carouselModel
                                    onWallpaperSelected: path => { Wallpapers.select(path, Appearance.m3colors.darkmode); GlobalStates.desktopMenuOpen = false; }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: !window.submenuOpen || ContextMenus.cascade
                                Repeater {
                                    model: root.arranged.bar
                                    delegate: RippleButton {
                                        required property var modelData
                                        Layout.fillWidth: true; implicitHeight: 36
                                        onClicked: root.activate(modelData)
                                        MaterialSymbol { anchors.centerIn: parent; text: modelData.symbol || "terminal"; iconSize: 20 }
                                        StyledToolTip { text: modelData.title }
                                    }
                                }
                            }
                            Repeater {
                                model: !window.submenuOpen || ContextMenus.cascade ? root.arranged.rows : []
                                delegate: Loader {
                                    id: row
                                    required property var modelData
                                    Layout.fillWidth: true
                                    sourceComponent: modelData.separator ? separator : menuRow
                                    Component { id: separator; Rectangle { implicitHeight: 1; color: Appearance.colors.colOutlineVariant; opacity: 0.5 } }
                                    Component {
                                        id: menuRow
                                        RippleButton {
                                            implicitHeight: ContextMenus.compact ? 34 : 46
                                            onClicked: root.activate(row.modelData)
                                            contentItem: RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                                MaterialSymbol { text: row.modelData.symbol || "terminal"; iconSize: 20 }
                                                StyledText { Layout.fillWidth: true; text: row.modelData.title; elide: Text.ElideRight }
                                                MaterialSymbol { visible: !!row.modelData.submenu; text: "chevron_right"; iconSize: 18 }
                                            }
                                        }
                                    }
                                }
                            }
                            RippleButton {
                                Layout.fillWidth: true; implicitHeight: 36
                                visible: window.submenuOpen && !ContextMenus.cascade
                                onClicked: window.submenuOpen = false
                                StyledText { anchors.centerIn: parent; text: qsTr("Back") }
                            }
                            Loader {
                                Layout.fillWidth: true
                                active: window.submenuOpen && !ContextMenus.cascade
                                visible: active
                                sourceComponent: WallpaperSubmenu {}
                            }
                        }
                    }
                }
            }
            Rectangle {
                id: cascadeCard
                visible: window.submenuOpen && ContextMenus.cascade
                width: Math.min(320, (window.width - 16) / ContextMenus.scale)
                height: Math.min(cascadeContents.implicitHeight, (window.height - 16) / ContextMenus.scale)
                scale: ContextMenus.scale; transformOrigin: Item.TopLeft
                x: cardSlot.x + cardSlot.width + width * ContextMenus.scale + 8 < window.width
                    ? cardSlot.x + cardSlot.width + 8 : Math.max(8, cardSlot.x - width * ContextMenus.scale - 8)
                y: Math.min(cardSlot.y, window.height - height * ContextMenus.scale - 8)
                radius: Appearance.rounding.large; color: Appearance.colors.colLayer0; clip: true
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                Flickable {
                    anchors.fill: parent; contentHeight: cascadeContents.implicitHeight; clip: true
                    WallpaperSubmenu { id: cascadeContents; width: parent.width }
                }
            }
        }
    }
}
