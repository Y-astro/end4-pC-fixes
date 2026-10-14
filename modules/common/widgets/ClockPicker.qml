import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitWidth: 248
    implicitHeight: 248

    property int durationSeconds: 1500
    property int secondsLeft: durationSeconds
    property bool running: false
    property int editSeconds: durationSeconds
    property bool dragging: false
    readonly property bool finished: !running && secondsLeft === 0 && durationSeconds > 0 && !dragging
    signal durationEdited(int seconds)

    onDurationSecondsChanged: if (!dragging) editSeconds = durationSeconds
    readonly property int displaySeconds: running || finished ? secondsLeft : editSeconds
    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real outerRadius: Math.min(width, height) / 2 - 16
    readonly property real ringGap: outerRadius * 34 / 118

    function unitValue(unit) {
        if (unit === 0) return Math.floor(displaySeconds / 3600);
        if (unit === 1) return Math.floor(displaySeconds / 60) % 60;
        return displaySeconds % 60;
    }

    function setUnit(unit, value) {
        const hours = unit === 0 ? value : Math.floor(editSeconds / 3600);
        const minutes = unit === 1 ? value : Math.floor(editSeconds / 60) % 60;
        const seconds = unit === 2 ? value : editSeconds % 60;
        editSeconds = hours * 3600 + minutes * 60 + seconds;
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Appearance.colors.colLayer1
    }

    Repeater {
        model: 3
        delegate: Item {
            id: ring
            required property int index
            anchors.fill: parent
            readonly property real numberRadius: root.outerRadius - index * root.ringGap
            readonly property int steps: index === 0 ? 24 : 60
            readonly property int value: root.unitValue(index)
            readonly property real angle: value / steps * 2 * Math.PI - Math.PI / 2
            readonly property string unit: index === 0 ? "h" : index === 1 ? "m" : "s"

            Rectangle {
                anchors.centerIn: parent
                width: (ring.numberRadius + 14) * 2
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colSubtext, 0.91)
            }

            Repeater {
                model: 12
                delegate: Item {
                    id: tick
                    required property int index
                    readonly property int value: index * (ring.steps / 12)
                    readonly property real angle: index / 12 * 2 * Math.PI - Math.PI / 2
                    x: root.centerX + ring.numberRadius * Math.cos(angle) - width / 2
                    y: root.centerY + ring.numberRadius * Math.sin(angle) - height / 2
                    width: 22
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: root.running && ring.value === tick.value
                            ? Appearance.colors.colPrimary : "transparent"
                    }
                    StyledText {
                        anchors.centerIn: parent
                        visible: root.running || root.finished || ring.value !== tick.value
                        text: tick.value
                        font.pixelSize: 10
                        font.weight: 700
                        color: root.running && ring.value === tick.value
                            ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                    }
                }
            }

            // Each hand ends on its own ring; the small unit suffix identifies it.
            Rectangle {
                visible: !root.running && !root.finished
                x: root.centerX
                y: root.centerY - height / 2
                width: ring.numberRadius
                height: 1.5
                radius: height / 2
                antialiasing: true
                color: Appearance.colors.colPrimary
                opacity: ring.index === 1 ? 0.9 : 0.55
                transform: Rotation { origin.x: 0; origin.y: 0.75; angle: ring.angle * 180 / Math.PI }
            }

            Rectangle {
                visible: !root.running && !root.finished
                x: root.centerX + ring.numberRadius * Math.cos(ring.angle) - width / 2
                y: root.centerY + ring.numberRadius * Math.sin(ring.angle) - height / 2
                width: 26
                height: 26
                radius: width / 2
                color: Appearance.colors.colPrimary
                StyledText {
                    anchors.centerIn: parent
                    text: ring.value + ring.unit
                    font.pixelSize: 9
                    font.weight: 700
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        visible: !root.running && !root.finished
        width: 8
        height: 8
        radius: 4
        color: Appearance.colors.colPrimary
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.running || root.finished
        text: {
            const total = Math.max(0, root.secondsLeft);
            return [Math.floor(total / 3600), Math.floor(total / 60) % 60, total % 60]
                .map(value => value.toString().padStart(2, "0")).join(":");
        }
        font.pixelSize: 18
        font.weight: 700
        font.features: { "tnum": 1 }
        color: Appearance.colors.colOnLayer1
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.running
        cursorShape: Qt.PointingHandCursor
        property int activeRing: 1

        function updateValue(mx, my) {
            let angle = Math.atan2(my - root.centerY, mx - root.centerX) + Math.PI / 2;
            if (angle < 0) angle += 2 * Math.PI;
            const steps = activeRing === 0 ? 24 : 60;
            root.setUnit(activeRing, Math.round(angle / (2 * Math.PI) * steps) % steps);
        }

        onPressed: event => {
            const radius = Math.hypot(event.x - root.centerX, event.y - root.centerY);
            activeRing = Math.max(0, Math.min(2, Math.round((root.outerRadius - radius) / root.ringGap)));
            root.dragging = true;
            updateValue(event.x, event.y);
        }
        onPositionChanged: event => { if (pressed) updateValue(event.x, event.y); }
        onReleased: {
            root.durationEdited(root.editSeconds);
            root.dragging = false;
        }
        onCanceled: {
            root.dragging = false;
            root.editSeconds = root.durationSeconds;
        }
    }
}
