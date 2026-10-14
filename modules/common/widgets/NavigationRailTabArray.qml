import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int currentIndex: 0
    property bool expanded: false
    property color colToggled: Appearance.colors.colSecondaryContainer
    default property alias data: tabBarColumn.data  
    implicitHeight: tabBarColumn.implicitHeight
    implicitWidth: tabBarColumn.implicitWidth
    Layout.topMargin: 25

    // Repeater is itself a child; only index the actual navigation buttons.
    readonly property var selectedButton: {
        const buttons = Array.from(tabBarColumn.children).filter(child => child.visualWidth !== undefined);
        return buttons[root.currentIndex] ?? null;
    }

    Rectangle {
        property real itemHeight: root.selectedButton?.baseSize ?? 56
        property real baseHighlightHeight: root.selectedButton?.baseHighlightHeight ?? 32
        anchors {
            top: tabBarColumn.top
            left: tabBarColumn.left
            topMargin: itemHeight * root.currentIndex + (root.expanded ? 0 : ((itemHeight - baseHighlightHeight) / 2))
        }
        radius: Config.options.settings.style === "minimal" ? Appearance.rounding.small : Appearance.rounding.full
        color: root.colToggled
        implicitHeight: root.expanded ? itemHeight : baseHighlightHeight
        implicitWidth: root.selectedButton?.visualWidth ?? 56

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: Appearance.animationCurves.expressiveFastSpatialDuration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
    }

    ColumnLayout {
        id: tabBarColumn
        anchors.fill: parent
        spacing: 0
    }
}
