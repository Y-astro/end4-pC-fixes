import QtQuick
import qs.modules.common

Item {
    id: marker

    required property bool focused
    required property bool occupied
    property bool hovered: false
    property real eatProgress: 0
    property int eatDirection: 1
    property int facingDirection: 1
    property bool isVertical: false
    property color activeColor: Appearance.colors.colPrimary
    property color occupiedColor: Appearance.colors.colPrimary
    property color emptyColor: Appearance.colors.colPrimary
    property color hoverColor: Appearance.colors.colPrimaryHover

    property int glyphSize: 15
    property int pelletSize: 5
    readonly property real eatOffset: 4
    readonly property real boundedEatProgress: Math.max(0, Math.min(1, eatProgress))
    readonly property real hoverFactor: hovered && boundedEatProgress === 0 ? 1.15 : 1

    implicitWidth: 26
    implicitHeight: 26
    opacity: 1 - boundedEatProgress
    scale: (1 - 0.45 * boundedEatProgress) * hoverFactor
    transformOrigin: Item.Center
    transform: Translate {
        x: !marker.isVertical ? -marker.eatDirection * marker.eatOffset * marker.boundedEatProgress : 0
        y: marker.isVertical ? -marker.eatDirection * marker.eatOffset * marker.boundedEatProgress : 0
    }

    Behavior on scale {
        enabled: marker.boundedEatProgress === 0
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Item {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        visible: marker.focused || marker.occupied

        transform: Scale {
            origin.x: width / 2
            origin.y: height / 2
            xScale: marker.focused ? marker.facingDirection : 1
            yScale: 1
        }

        Text {
            anchors.centerIn: parent
            text: marker.focused ? String.fromCodePoint(0xF0BAF) : String.fromCodePoint(0xF02A0)
            color: marker.hovered ? marker.hoverColor
                 : marker.focused ? marker.activeColor
                                  : marker.occupiedColor
            font.family: Appearance.font.family.iconNerd || "JetBrainsMono Nerd Font"
            font.pixelSize: marker.glyphSize
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering

            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle {
        visible: !marker.focused && !marker.occupied
        anchors.centerIn: parent
        width: marker.pelletSize
        height: width
        radius: width / 2
        color: marker.hovered ? marker.hoverColor : marker.emptyColor
        opacity: marker.hovered ? 0.90 : 0.55
        antialiasing: true

        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
}
