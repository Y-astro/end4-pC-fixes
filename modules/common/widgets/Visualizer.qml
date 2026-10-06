import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool mirrored: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property list<real> points: GlobalStates.visualizerPoints
    property int barCount: 20
    property real dotSize: 3
    property real dotSpacing: 3
    property real maxBarHeight: (vertical
        ? Appearance.sizes.verticalBarWidth
        : Appearance.sizes.barHeight) * 0.7
    property real maxVisualizerValue: 1000
    property color barColor: Appearance.colors.colPrimary
    property bool useGpuShader: true

    implicitWidth: vertical
        ? Appearance.sizes.verticalBarWidth
        : (isMaterial
            ? barsRow.implicitWidth + 16
            : barCount * (dotSize + dotSpacing))
    implicitHeight: vertical
        ? (isMaterial
            ? barsColumn.implicitHeight + 16
            : barCount * (dotSize + dotSpacing))
        : Appearance.sizes.barHeight

    transform: Scale {
        xScale: !root.vertical && root.mirrored ? -1 : 1
        origin.x: root.width / 2
    }

    // ── Single-Pass GPU Shader Visualizer (SDF Bars) ──
    SpectrumField {
        id: gpuSpectrum
        visible: root.useGpuShader
        anchors.centerIn: parent
        width: root.vertical ? root.maxBarHeight : (root.barCount * (root.dotSize + root.dotSpacing))
        height: root.vertical ? (root.barCount * (root.dotSize + root.dotSpacing)) : root.maxBarHeight
        grow: root.vertical ? (root.mirrored ? "left" : "right") : "center"
        style: "bars"
        shape: "rounded"
        thickness: 0.58
        glow: 0.2
        ramp: [root.barColor, root.barColor]
        fade: root.isPlaying ? 0.9 : 0.0

        levels: {
            if (!root.isPlaying || root.points.length === 0) return []
            const count = root.barCount
            const res = new Array(count)
            const ptsLen = root.points.length
            for (let i = 0; i < count; i++) {
                const rawIdx = root.vertical && root.mirrored ? (count - 1 - i) : i
                const idx = Math.floor(rawIdx * ptsLen / count)
                const v = root.points[idx] ?? 0
                res[i] = Math.min(1.0, Math.max(0.04, v / root.maxVisualizerValue))
            }
            return res
        }
    }

    // ── CPU Multi-Rectangle Fallback ──
    Row {
        id: barsRow
        visible: !root.vertical && !root.useGpuShader
        anchors.centerIn: parent
        spacing: root.dotSpacing

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                width: root.dotSize
                property real pointValue: {
                    if (!root.isPlaying || root.points.length === 0) return root.dotSize
                    const idx = Math.floor(index * root.points.length / root.barCount)
                    const v = root.points[idx] ?? 0
                    return Math.max(root.dotSize, (v / root.maxVisualizerValue) * root.maxBarHeight)
                }
                height: pointValue
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.colors.colPrimary
                opacity: root.isPlaying ? 0.85 : 0.3
                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }
    }

    Column {
        id: barsColumn
        visible: root.vertical && !root.useGpuShader
        anchors.centerIn: parent
        spacing: root.dotSpacing

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                height: root.dotSize
                property real pointValue: {
                    if (!root.isPlaying || root.points.length === 0) return root.dotSize
                    const rawIndex = root.mirrored ? (root.barCount - 1 - index) : index
                    const idx = Math.floor(rawIndex * root.points.length / root.barCount)
                    const v = root.points[idx] ?? 0
                    return Math.max(root.dotSize, (v / root.maxVisualizerValue) * root.maxBarHeight)
                }
                width: pointValue
                radius: height / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: Appearance.colors.colPrimary
                opacity: root.isPlaying ? 0.85 : 0.3
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }
    }
}