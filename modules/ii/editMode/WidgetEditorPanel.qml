import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import "."

Rectangle {
    id: root
    required property var screen
    signal dragBy(real dx, real dy)
    property string query: ""
    property bool showingOptions: false
    property var collapsedCategories: ({})
    readonly property var instance: (Config.options.background.activeWidgets ?? []).find(entry => (entry.id ?? entry.instanceId) === GlobalStates.editWidgetInstanceId)
    readonly property var entry: GlobalStates.editWidgetInstanceId ? root.instance : Config.options.background.widgets[GlobalStates.editWidgetKey]
    readonly property var metadata: root.instance ? WidgetsRegistry.getWidgetMetadata(root.instance.widgetId) : null
    readonly property var legacy: LegacyWidgetCatalog.widgets.find(entry => entry.id === GlobalStates.editWidgetKey)
    readonly property string selectionName: (root.metadata ? root.metadata.name : "") || (root.legacy ? root.legacy.name : "") || ""

    function normalizeCategory(cat) {
        if (!cat) return "Other";
        const c = String(cat).trim();
        const lower = c.toLowerCase();
        if (lower === "clock" || lower === "date") return "Clock";
        if (lower === "weather") return "Weather";
        if (lower === "productivity" || lower === "utility") return "Productivity";
        if (lower === "media") return "Media";
        if (lower === "system" || lower === "resources" || lower === "devices") return "System";
        if (lower === "images" || lower === "photo" || lower === "photos" || lower === "image") return "Images";
        return c;
    }

    function displayCategory(normCat) {
        if (normCat === "Clock") return "Clocks";
        return normCat;
    }

    function toggleCategory(cat) {
        const copy = Object.assign({}, root.collapsedCategories);
        if (copy[cat]) delete copy[cat];
        else copy[cat] = true;
        root.collapsedCategories = copy;
    }

    readonly property var catalog: {
        const q = (root.query || "").trim().toLowerCase();
        const legacyItems = LegacyWidgetCatalog.widgets.map(w => {
            const norm = root.normalizeCategory(w.category);
            return Object.assign({}, w, {
                legacy: true,
                normalizedCategory: norm,
                displayCategory: root.displayCategory(norm)
            });
        });
        const registryItems = WidgetsRegistry.allWidgets.map(w => {
            const norm = root.normalizeCategory(w.category);
            return Object.assign({}, w, {
                id: w.widgetId,
                legacy: false,
                normalizedCategory: norm,
                displayCategory: root.displayCategory(norm)
            });
        });
        return legacyItems.concat(registryItems)
            .filter(widget => {
                if (!q) return true;
                const searchString = (widget.name + " " + (widget.category || "") + " " + widget.normalizedCategory + " " + widget.displayCategory).toLowerCase();
                return searchString.includes(q);
            })
            .sort((a, b) => {
                if (a.displayCategory !== b.displayCategory) {
                    return a.displayCategory.localeCompare(b.displayCategory);
                }
                return a.name.localeCompare(b.name);
            });
    }

    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.large
    clip: true

    function setPosition(key, value) {
        if (!root.entry) return;
        if (GlobalStates.editWidgetInstanceId)
            Config.options.background.activeWidgets = Config.options.background.activeWidgets.map(entry => entry.id === GlobalStates.editWidgetInstanceId ? Object.assign({}, entry, { [key]: value }) : entry);
        else root.entry[key] = value;
    }
    function selectOrAdd(widget) {
        if (widget.legacy) {
            const cfg = Config.options.background.widgets[widget.id];
            if (cfg && cfg.enable) {
                GlobalStates.selectEditWidget(widget.id, "", widget.id);
            } else {
                root.add(widget);
            }
            return;
        }
        const activeList = Config.options.background.activeWidgets ?? [];
        const matching = activeList.filter(entry => (entry.widgetId ?? entry.id) === widget.id);
        if (matching.length === 0) {
            root.add(widget);
            return;
        }
        let target = matching.find(entry => (entry.id ?? entry.instanceId) === GlobalStates.editWidgetInstanceId);
        if (!target) {
            const currentMonitor = root.screen ? root.screen.name : (GlobalStates.editModeMonitorName || "");
            target = matching.find(entry => !entry.monitorName || entry.monitorName === currentMonitor);
        }
        if (!target) target = matching[0];
        const targetId = String(target.id ?? target.instanceId ?? "");
        GlobalStates.selectEditWidget(targetId, targetId, widget.id);
    }
    function add(widget) {
        if (widget.legacy) {
            const cfg = Config.options.background.widgets[widget.id];
            cfg.enable = true;
            GlobalStates.selectEditWidget(widget.id, "", widget.id);
        } else {
            const id = widget.id + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 6);
            Config.options.background.activeWidgets = (Config.options.background.activeWidgets ?? []).concat([{
                id: id, widgetId: widget.id, x: Math.max(24, root.screen.width / 3 - 150), y: Math.max(72, root.screen.height / 3 - 120),
                z: 10, placementStrategy: "free", monitorName: root.screen.name, lockBehavior: "keep", pinned: false
            }]);
            GlobalStates.selectEditWidget(id, id, widget.id);
        }
    }
    function removeSelection() {
        const instanceId = GlobalStates.editWidgetInstanceId;
        if (instanceId) {
            Config.options.background.activeWidgets = (Config.options.background.activeWidgets ?? []).filter(entry => (entry.id ?? entry.instanceId) !== instanceId);
        } else if (root.entry) {
            root.entry.enable = false;
        }
        GlobalStates.selectEditWidget("", "", "");
    }
    function duplicate() {
        if (!root.instance) return;
        const id = root.instance.widgetId + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 6);
        const copy = Object.assign({}, root.instance, { id: id, x: root.instance.x + 24, y: root.instance.y + 24 });
        Config.options.background.activeWidgets = (Config.options.background.activeWidgets ?? []).concat([copy]);
        GlobalStates.selectEditWidget(copy.id, copy.id, GlobalStates.editWidgetConfigName);
    }
    Connections {
        target: GlobalStates
        function onEditWidgetKeyChanged() { root.showingOptions = false; }
        function onEditWidgetOptionsRequested() { root.showingOptions = true; }
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: wheel => wheel.accepted = true }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                id: headerDragArea
                Layout.fillWidth: true
                implicitHeight: 40
                readonly property bool hovered: headerHover.hovered && !headerDrag.active

                HoverHandler {
                    id: headerHover
                    cursorShape: Qt.OpenHandCursor
                }

                DragHandler {
                    id: headerDrag
                    target: null
                    grabPermissions: PointerHandler.CanTakeOverFromAnything
                    cursorShape: Qt.ClosedHandCursor

                    property real lastSceneX: 0
                    property real lastSceneY: 0

                    onActiveChanged: {
                        if (active) {
                            lastSceneX = centroid.scenePosition.x;
                            lastSceneY = centroid.scenePosition.y;
                        }
                    }

                    onCentroidChanged: {
                        if (!active) return;
                        var cx = centroid.scenePosition.x;
                        var cy = centroid.scenePosition.y;
                        var dx = cx - lastSceneX;
                        var dy = cy - lastSceneY;
                        lastSceneX = cx;
                        lastSceneY = cy;
                        if (dx !== 0 || dy !== 0) {
                            root.dragBy(dx, dy);
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 6

                    MaterialSymbol {
                        text: "drag_indicator"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                        opacity: headerDrag.active ? 1.0 : (headerHover.hovered ? 0.8 : 0.4)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Edit desktop")
                        font.pixelSize: 22
                        elide: Text.ElideRight
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: headerDragArea.hovered
                    text: qsTr("Drag to move")
                }
            }

            RippleButton {
                implicitWidth: 70; implicitHeight: 40
                onClicked: GlobalStates.closeEditMode()
                StyledText { anchors.centerIn: parent; text: qsTr("Done") }
            }
        }
        ConfigSelectionArray {
            Layout.fillWidth: true
            options: [{ value: "widgets", displayName: qsTr("Widgets"), icon: "widgets" }, { value: "bar", displayName: qsTr("Bar"), icon: "view_stream" }]
            currentValue: GlobalStates.editModePage
            onSelected: value => GlobalStates.editModePage = value
        }
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: GlobalStates.editModePage === "bar"
            visible: active
            sourceComponent: Component { LegacyBarLayoutConfig {} }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: GlobalStates.editModePage !== "bar"
            spacing: 8
            StyledText { Layout.fillWidth: true; text: qsTr("Drag widgets to move them. Ctrl-click to select several, or drag a selection box on the desktop."); wrapMode: Text.Wrap; font.pixelSize: 12 }
            RowLayout {
                visible: root.entry !== undefined && root.entry !== null
                Layout.fillWidth: true
                StyledText { Layout.fillWidth: true; text: root.selectionName; font.bold: true; elide: Text.ElideRight }
                RippleButton {
                    implicitWidth: 36; implicitHeight: 36
                    visible: root.instance !== undefined
                    onClicked: root.duplicate()
                    MaterialSymbol { anchors.centerIn: parent; text: "content_copy"; iconSize: 20 }
                    StyledToolTip { text: qsTr("Duplicate") }
                }
                RippleButton {
                    implicitWidth: 36; implicitHeight: 36
                    onClicked: root.removeSelection()
                    MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 20 }
                    StyledToolTip { text: qsTr("Remove") }
                }
            }
            RowLayout {
                visible: !!root.entry
                Layout.fillWidth: true
                Repeater {
                    model: ["x", "y"]
                    delegate: ConfigSpinBox {
                        required property string modelData
                        Layout.fillWidth: true
                        text: modelData.toUpperCase(); icon: "open_with"
                        from: 0; to: modelData === "x" ? root.screen.width : root.screen.height
                        value: Math.round((root.entry && root.entry[modelData] !== undefined) ? root.entry[modelData] : 0)
                        onValueChanged: if (root.entry && root.entry[modelData] !== value) root.setPosition(modelData, value)
                    }
                }
            }
            ConfigComboBox {
                Layout.fillWidth: true
                visible: !!root.entry
                text: qsTr("Placement")
                fieldWidth: 175
                currentValue: (root.entry && root.entry.placementStrategy) ? root.entry.placementStrategy : "free"
                model: [{ value: "free", displayName: qsTr("Free") }, { value: "leastBusy", displayName: qsTr("Least busy") }, { value: "mostBusy", displayName: qsTr("Most busy") }]
                onSelected: value => root.setPosition("placementStrategy", value)
            }
            ConfigComboBox {
                Layout.fillWidth: true
                visible: !!root.instance
                text: qsTr("Lock screen")
                fieldWidth: 175
                currentValue: (root.instance && root.instance.lockBehavior) ? root.instance.lockBehavior : "keep"
                model: [{ value: "keep", displayName: qsTr("Show") }, { value: "hide", displayName: qsTr("Hide") }, { value: "lockOnly", displayName: qsTr("Only when locked") }]
                onSelected: value => root.setPosition("lockBehavior", value)
            }
            ConfigSwitch {
                Layout.fillWidth: true
                visible: !!root.instance
                text: qsTr("Pinned")
                checked: !!(root.instance && root.instance.pinned)
                onCheckedChanged: if (root.instance && checked !== root.instance.pinned) root.setPosition("pinned", checked)
            }
            RippleButton {
                Layout.fillWidth: true; implicitHeight: 36
                visible: !!root.entry
                onClicked: root.showingOptions = !root.showingOptions
                StyledText { anchors.centerIn: parent; text: root.showingOptions ? qsTr("Back to catalog") : qsTr("Widget options") }
            }
            Loader {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: active
                active: root.showingOptions
                source: (root.metadata && root.metadata.configPage) ? Qt.resolvedUrl("../../settings/configs/" + root.metadata.configPage) : ""
                sourceComponent: (root.metadata && root.metadata.configPage) ? null : legacyOptions
                onLoaded: if (item && item.goBack) item.goBack.connect(() => root.showingOptions = false)
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: !root.showingOptions
                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("Find a widget…")
                    onTextEdited: root.query = text
                }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 0
                    model: root.catalog

                    section.property: "displayCategory"
                    section.criteria: ViewSection.FullString
                    section.delegate: Component {
                        Rectangle {
                            id: sectionHeader
                            required property string section
                            width: ListView.view.width
                            implicitHeight: 34
                            color: "transparent"

                            property bool isCollapsed: !root.query && !!root.collapsedCategories[section]

                            RippleButton {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                anchors.bottomMargin: 2
                                onClicked: root.toggleCategory(sectionHeader.section)
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 8
                                    MaterialSymbol {
                                        text: sectionHeader.isCollapsed ? "chevron_right" : "expand_more"
                                        iconSize: 18
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: sectionHeader.section
                                        font.bold: true
                                        font.pixelSize: 13
                                    }
                                }
                            }
                        }
                    }

                    delegate: Item {
                        id: catalogItemWrapper
                        required property var modelData
                        width: ListView.view.width
                        property bool isCollapsed: !root.query && !!root.collapsedCategories[modelData.displayCategory]
                        implicitHeight: isCollapsed ? 0 : 60
                        height: implicitHeight
                        visible: !isCollapsed
                        clip: true

                        RippleButton {
                            id: catalogRow
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 56
                            onClicked: root.selectOrAdd(catalogItemWrapper.modelData)
                            contentItem: RowLayout {
                                anchors.fill: parent; anchors.margins: 8
                                MaterialSymbol { text: catalogItemWrapper.modelData.icon || "widgets"; iconSize: 24 }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    StyledText { Layout.fillWidth: true; text: catalogItemWrapper.modelData.name; elide: Text.ElideRight }
                                    StyledText { text: catalogItemWrapper.modelData.category || ""; font.pixelSize: 11 }
                                }
                                MaterialSymbol {
                                    text: (catalogItemWrapper.modelData.legacy ? (Config.options.background.widgets[catalogItemWrapper.modelData.id] && Config.options.background.widgets[catalogItemWrapper.modelData.id].enable) : Config.isWidgetActive(catalogItemWrapper.modelData.id)) ? "check" : "add"
                                    iconSize: 20
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: legacyOptions
        LegacyWidgetOptions { configName: GlobalStates.editWidgetConfigName }
    }
}
