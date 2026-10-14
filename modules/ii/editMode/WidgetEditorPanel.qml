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
    property string query: ""
    property bool showingOptions: false
    readonly property var instance: (Config.options.background.activeWidgets ?? []).find(entry => entry.id === GlobalStates.editWidgetInstanceId)
    readonly property var entry: GlobalStates.editWidgetInstanceId ? root.instance : Config.options.background.widgets[GlobalStates.editWidgetKey]
    readonly property var metadata: root.instance ? WidgetsRegistry.getWidgetMetadata(root.instance.widgetId) : null
    readonly property var legacy: LegacyWidgetCatalog.widgets.find(entry => entry.id === GlobalStates.editWidgetKey)
    readonly property string selectionName: (root.metadata ? root.metadata.name : "") || (root.legacy ? root.legacy.name : "") || ""
    readonly property var catalog: LegacyWidgetCatalog.widgets.map(widget => Object.assign({}, widget, { legacy: true }))
        .concat(WidgetsRegistry.allWidgets.map(widget => Object.assign({}, widget, { id: widget.widgetId, legacy: false })))
        .filter(widget => !root.query || (widget.name + " " + widget.category).toLowerCase().includes(root.query.toLowerCase()))
    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.large
    clip: true

    function setPosition(key, value) {
        if (!root.entry) return;
        if (GlobalStates.editWidgetInstanceId)
            Config.options.background.activeWidgets = Config.options.background.activeWidgets.map(entry => entry.id === GlobalStates.editWidgetInstanceId ? Object.assign({}, entry, { [key]: value }) : entry);
        else root.entry[key] = value;
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
        if (GlobalStates.editWidgetInstanceId)
            Config.options.background.activeWidgets = Config.options.background.activeWidgets.filter(entry => entry.id !== GlobalStates.editWidgetInstanceId);
        else if (root.entry) root.entry.enable = false;
        GlobalStates.selectEditWidget("", "", "");
    }
    function duplicate() {
        if (!root.instance) return;
        const copy = Object.assign({}, root.instance, { id: root.instance.widgetId + "-" + Date.now().toString(36), x: root.instance.x + 24, y: root.instance.y + 24 });
        Config.options.background.activeWidgets = Config.options.background.activeWidgets.concat([copy]);
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
            StyledText { Layout.fillWidth: true; text: qsTr("Edit desktop"); font.pixelSize: 22 }
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
                    clip: true; spacing: 4
                    model: root.catalog
                    delegate: RippleButton {
                        id: catalogRow
                        required property var modelData
                        width: ListView.view.width
                        implicitHeight: 56
                        onClicked: root.add(modelData)
                        contentItem: RowLayout {
                            anchors.fill: parent; anchors.margins: 8
                            MaterialSymbol { text: catalogRow.modelData.icon || "widgets"; iconSize: 24 }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 0
                                StyledText { Layout.fillWidth: true; text: catalogRow.modelData.name; elide: Text.ElideRight }
                                StyledText { text: catalogRow.modelData.category || ""; font.pixelSize: 11 }
                            }
                            MaterialSymbol { text: catalogRow.modelData.legacy && (Config.options.background.widgets[catalogRow.modelData.id] && Config.options.background.widgets[catalogRow.modelData.id].enable) ? "check" : "add"; iconSize: 20 }
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
