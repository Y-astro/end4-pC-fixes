import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property list<var> points: []
    property list<var> smoothPoints: []
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color color: Appearance.m3colors.m3primary
    property bool useGpuShader: true

    anchors.fill: parent

    // ── Single-Pass GPU Shader Visualizer (SDF Wave) ──
    SpectrumField {
        id: gpuWave
        visible: root.useGpuShader
        anchors.fill: parent
        style: "wave"
        grow: "up"
        glow: 0.35
        ramp: [
            Qt.rgba(root.color.r, root.color.g, root.color.b, 0.25),
            Qt.rgba(root.color.r, root.color.g, root.color.b, 0.45)
        ]
        fade: root.live && root.points && root.points.length > 0 ? 0.95 : 0.0

        levels: {
            if (!root.live || !root.points || root.points.length === 0) return []
            const pts = root.points
            const maxVal = root.maxVisualizerValue || 1
            const len = Math.min(pts.length, 64)
            const out = new Array(len)
            for (let i = 0; i < len; i++) {
                out[i] = Math.min(1.0, Math.max(0.0, (pts[i] || 0) / maxVal))
            }
            return out
        }
    }

    // ── CPU Canvas Fallback ──
    Canvas {
        id: cpuCanvas
        visible: !root.useGpuShader
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var pts = root.points;
            var maxVal = root.maxVisualizerValue || 1;
            var h = height;
            var w = width;
            var n = pts ? pts.length : 0;
            if (n < 2) return;

            var smoothWindow = root.smoothing;
            root.smoothPoints = [];
            for (var i = 0; i < n; ++i) {
                var sum = 0, count = 0;
                for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                    var idx = Math.max(0, Math.min(n - 1, i + j));
                    sum += pts[idx];
                    count++;
                }
                root.smoothPoints.push(sum / count);
            }
            if (!root.live) root.smoothPoints.fill(0);

            ctx.beginPath();
            ctx.moveTo(0, h);
            for (var k = 0; k < n; ++k) {
                var x = k * w / (n - 1);
                var y = h - (root.smoothPoints[k] / maxVal) * h;
                ctx.lineTo(x, y);
            }
            ctx.lineTo(w, h);
            ctx.closePath();

            ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.15);
            ctx.fill();
        }

        layer.enabled: !root.useGpuShader
        layer.effect: MultiEffect {
            source: cpuCanvas
            saturation: 0.2
            blurEnabled: true
            blurMax: 7
            blur: 1
        }
    }

    Connections {
        target: root
        function onPointsChanged() {
            if (!root.useGpuShader) {
                cpuCanvas.requestPaint();
            }
        }
    }
}