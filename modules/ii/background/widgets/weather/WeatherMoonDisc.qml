import QtQuick

Canvas {
    id: root

    property real frac: 0.5
    property bool waxing: true
    property color color: "#F0F4FF"
    property color darkColor: "#141923"
    property color rimColor: Qt.rgba(1.0, 1.0, 1.0, 0.35)

    onFracChanged: requestPaint()
    onWaxingChanged: requestPaint()
    onColorChanged: requestPaint()
    onDarkColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        var sz = Math.min(width, height);
        if (sz <= 1) return;
        var r = sz / 2;
        var cx = width / 2;
        var cy = height / 2;

        ctx.reset();
        ctx.clearRect(0, 0, width, height);

        // Soft moonlight halo around the disc
        var halo = ctx.createRadialGradient(cx, cy, r * 0.7, cx, cy, r * 1.3);
        halo.addColorStop(0.0, "rgba(240, 244, 255, 0.18)");
        halo.addColorStop(1.0, "rgba(240, 244, 255, 0)");
        ctx.fillStyle = halo;
        ctx.beginPath();
        ctx.arc(cx, cy, r * 1.3, 0, Math.PI * 2);
        ctx.fill();

        // 1. Clip everything to the circular moon disc
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.closePath();
        ctx.save();
        ctx.clip();

        // 2. Night side (dark shadowed disc)
        ctx.fillStyle = root.darkColor;
        ctx.fillRect(cx - r, cy - r, sz, sz);

        // 3. Lit hemisphere (right side if waxing, left side if waning)
        ctx.fillStyle = root.color;
        if (root.waxing) {
            ctx.fillRect(cx, cy - r, r, sz);
        } else {
            ctx.fillRect(cx - r, cy - r, r, sz);
        }

        // 4. Terminator: squashed circle based on illumination fraction
        var rx = r * Math.abs(1.0 - 2.0 * root.frac);
        if (rx > 0.01) {
            ctx.fillStyle = (root.frac < 0.5) ? root.darkColor : root.color;
            ctx.save();
            ctx.translate(cx, cy);
            ctx.scale(rx / r, 1.0);
            ctx.beginPath();
            ctx.arc(0, 0, r, 0, Math.PI * 2);
            ctx.closePath();
            ctx.fill();
            ctx.restore();
        }

        // 5. Subtle lunar maria (seas/craters) for authentic moon texture
        ctx.fillStyle = "rgba(100, 115, 140, 0.16)";
        ctx.beginPath();
        ctx.arc(cx - r * 0.28, cy - r * 0.18, r * 0.18, 0, Math.PI * 2);
        ctx.arc(cx + r * 0.22, cy + r * 0.22, r * 0.14, 0, Math.PI * 2);
        ctx.arc(cx - r * 0.08, cy + r * 0.36, r * 0.12, 0, Math.PI * 2);
        ctx.arc(cx + r * 0.12, cy - r * 0.32, r * 0.10, 0, Math.PI * 2);
        ctx.fill();

        ctx.restore();

        // 6. Delicate outer lunar rim
        ctx.beginPath();
        ctx.arc(cx, cy, r - 0.5, 0, Math.PI * 2);
        ctx.lineWidth = 1.0;
        ctx.strokeStyle = root.rimColor;
        ctx.stroke();
    }
}
