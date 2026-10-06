import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.services
import "WeatherAstronomy.js" as Astro

Item {
    id: root
    clip: true

    property real cardRadius: Appearance.rounding?.verylarge ?? 30
    property int weatherCode: Weather.data?.wCode ?? 800
    property string weatherDescription: Weather.data?.description ?? ""
    property color primaryColor: Appearance.colors.colPrimary
    property color onContainerColor: Appearance.colors.colOnPrimaryContainer

    property real sunX: width - 40
    property real sunY: 42

    property string forcedCondition: "" // "", "sunny", "partly_cloudy", "cloudy", "rain"
    property bool active: true

    property real simulatedHour: -1
    property real simulatedTemp: -999

    readonly property var solarInfo: Astro.getSolarTimes(Weather.data, new Date(), root.simulatedHour)
    readonly property bool isDayTime: solarInfo.isDay
    readonly property real tempFactor: Astro.getTemperatureFactor(root.simulatedTemp > -990 ? root.simulatedTemp : (Weather.data?.tempNum ?? 25), Weather.useUSCS)
    readonly property real solarRayBrightness: solarInfo.brightness * tempFactor

    property bool isDay: isDayTime

    readonly property string descLower: (weatherDescription || "").toLowerCase()

    readonly property bool isRainCondition: {
        return (weatherCode >= 200 && weatherCode < 700) ||
               descLower.indexOf("rain") !== -1 ||
               descLower.indexOf("drizzle") !== -1 ||
               descLower.indexOf("storm") !== -1 ||
               descLower.indexOf("thunder") !== -1 ||
               descLower.indexOf("shower") !== -1
    }

    readonly property bool isCloudyCondition: {
        return !isRainCondition && (
            weatherCode === 803 || weatherCode === 804 ||
            descLower.indexOf("overcast") !== -1 ||
            descLower.indexOf("broken clouds") !== -1
        )
    }

    readonly property bool isPartlyCloudyCondition: {
        return !isRainCondition && !isCloudyCondition && (
            weatherCode === 801 || weatherCode === 802 ||
            descLower.indexOf("few clouds") !== -1 ||
            descLower.indexOf("scattered") !== -1 ||
            descLower.indexOf("partly") !== -1
        )
    }

    readonly property bool isSunnyCondition: {
        return !isRainCondition && !isCloudyCondition && !isPartlyCloudyCondition
    }

    readonly property string activeKind: {
        if (forcedCondition === "sunny" || forcedCondition === "sun") return "sunny";
        if (forcedCondition === "partly_cloudy" || forcedCondition === "few_clouds") return "partly_cloudy";
        if (forcedCondition === "cloudy" || forcedCondition === "cloud") return "cloudy";
        if (forcedCondition === "rain" || forcedCondition === "rainy") return "rain";

        if (isRainCondition) return "rain";
        if (isCloudyCondition) return "cloudy";
        if (isPartlyCloudyCondition) return "partly_cloudy";
        return "sunny";
    }

    readonly property bool hasSunRays: isDayTime && (activeKind === "sunny" || activeKind === "partly_cloudy") && (solarRayBrightness > 0.01)
    readonly property bool hasClouds: activeKind === "cloudy" || activeKind === "partly_cloudy"
    readonly property bool hasRain: activeKind === "rain"

    property int frame: 0
    property real flash: 0
    property var rays: []
    property var clouds: []
    property var rainDrops: []
    property var splashes: []

    layer.enabled: root.width > 0 && root.height > 0
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: Math.max(1, root.width)
            height: Math.max(1, root.height)
            radius: root.cardRadius
        }
    }

    function initRays() {
        var arr = [
            { baseAngle: 1.40, widthAngle: 0.14, length: 190, speed: 0.024, phase: 0.0, swaySpeed: 0.007, swayAmp: 0.04, isPartly: false },
            { baseAngle: 1.75, widthAngle: 0.13, length: 230, speed: 0.019, phase: 1.5, swaySpeed: 0.009, swayAmp: 0.05, isPartly: true },
            { baseAngle: 2.10, widthAngle: 0.16, length: 270, speed: 0.028, phase: 3.1, swaySpeed: 0.006, swayAmp: 0.04, isPartly: false },
            { baseAngle: 2.45, widthAngle: 0.15, length: 310, speed: 0.021, phase: 4.6, swaySpeed: 0.008, swayAmp: 0.06, isPartly: true },
            { baseAngle: 2.80, widthAngle: 0.17, length: 290, speed: 0.026, phase: 0.8, swaySpeed: 0.007, swayAmp: 0.05, isPartly: false },
            { baseAngle: 3.14, widthAngle: 0.14, length: 260, speed: 0.018, phase: 2.3, swaySpeed: 0.010, swayAmp: 0.04, isPartly: true },
            { baseAngle: 3.48, widthAngle: 0.15, length: 220, speed: 0.025, phase: 5.3, swaySpeed: 0.008, swayAmp: 0.05, isPartly: false },
            { baseAngle: 3.82, widthAngle: 0.13, length: 170, speed: 0.022, phase: 3.8, swaySpeed: 0.009, swayAmp: 0.03, isPartly: true },
            { baseAngle: 0.70, widthAngle: 0.12, length: 130, speed: 0.020, phase: 2.7, swaySpeed: 0.008, swayAmp: 0.03, isPartly: false }
        ];
        root.rays = arr;
    }

    function initClouds() {
        var arr = [];
        var isPartly = (root.activeKind === "partly_cloudy");
        var count = isPartly ? 4 : 7;
        var w = Math.max(100, root.width);
        var h = Math.max(80, root.height);
        for (var i = 0; i < count; i++) {
            arr.push({
                x: (i / count) * (w - 60) + 15 + (Math.random() - 0.5) * 30,
                y: 18 + Math.random() * (h * 0.40),
                scale: isPartly ? (0.60 + Math.random() * 0.30) : (0.75 + Math.random() * 0.35),
                speed: 0.22 + Math.random() * 0.18,
                life: i / count,
                lifeSpeed: 0.0008 + Math.random() * 0.0006
            });
        }
        root.clouds = arr;
    }

    function initRain() {
        var arr = [];
        var count = 48;
        var w = Math.max(100, root.width);
        var h = Math.max(80, root.height);
        for (var i = 0; i < count; i++) {
            arr.push({
                x: Math.random() * (w + 60) - 20,
                y: Math.random() * (h + 40) - 20,
                len: 13 + Math.random() * 13,
                speed: 9.0 + Math.random() * 6.5,
                alpha: 0.18 + Math.random() * 0.24,
                thickness: 1.2 + Math.random() * 0.5
            });
        }
        root.rainDrops = arr;
        root.splashes = [];
    }

    function stepClouds() {
        var isPartly = (root.activeKind === "partly_cloudy");
        var count = isPartly ? 4 : root.clouds.length;
        var w = root.width;
        var h = root.height;
        for (var i = 0; i < count; i++) {
            var c = root.clouds[i];
            if (!c) continue;
            c.x += c.speed;
            c.life += c.lifeSpeed;
            if (c.life >= 1.0 || c.x > w + 60) {
                c.life = 0;
                c.x = Math.random() < 0.5 ? (-50 - Math.random() * 20) : (Math.random() * (w * 0.4));
                c.y = 18 + Math.random() * (h * 0.42);
                c.scale = isPartly ? (0.60 + Math.random() * 0.30) : (0.75 + Math.random() * 0.35);
                c.speed = 0.22 + Math.random() * 0.18;
                c.lifeSpeed = 0.0008 + Math.random() * 0.0006;
            }
        }
    }

    function stepRain() {
        var w = root.width;
        var h = root.height;
        for (var i = 0; i < root.rainDrops.length; i++) {
            var d = root.rainDrops[i];
            if (!d) continue;
            d.y += d.speed;
            d.x -= d.speed * 0.25;
            if (d.y > h + 10) {
                if (d.x > 10 && d.x < w - 10 && root.splashes.length < 8) {
                    root.splashes.push({
                        x: d.x,
                        y: h - 3 - Math.random() * 5,
                        r: 1.5,
                        alpha: 0.35
                    });
                }
                d.y = -d.len - Math.random() * 20;
                d.x = Math.random() * (w + 60);
                d.speed = 9.0 + Math.random() * 6.5;
            }
        }

        for (var j = root.splashes.length - 1; j >= 0; j--) {
            var s = root.splashes[j];
            s.r += 0.55;
            s.alpha -= 0.045;
            if (s.alpha <= 0) {
                root.splashes.splice(j, 1);
            }
        }
    }

    function drawRays(ctx, w, h, pr, pg, pb) {
        var cx = root.sunX;
        var cy = root.sunY;
        var isPartly = (root.activeKind === "partly_cloudy");
        var rayScale = (isPartly ? 0.55 : 1.0) * root.solarRayBrightness;
        if (rayScale <= 0.005 || !root.isDayTime) return;

        // Warm golden daylight blend
        var sunR = Math.min(255, Math.round(pr * 0.55 + 255 * 0.45));
        var sunG = Math.min(255, Math.round(pg * 0.55 + 228 * 0.45));
        var sunB = Math.min(255, Math.round(pb * 0.55 + 155 * 0.45));

        // Gentle breathing halo behind the badge (scaled by solarRayBrightness)
        var haloPulse = 0.5 + 0.5 * Math.sin(root.frame * 0.03);
        var haloGrad = ctx.createRadialGradient(cx, cy, 12, cx, cy, 72);
        var haloAlpha = (isPartly ? 0.16 : 0.28) * (0.85 + 0.15 * haloPulse) * root.solarRayBrightness;
        haloGrad.addColorStop(0.0, "rgba(" + sunR + "," + sunG + "," + sunB + "," + haloAlpha + ")");
        haloGrad.addColorStop(0.4, "rgba(" + sunR + "," + sunG + "," + sunB + "," + (haloAlpha * 0.4) + ")");
        haloGrad.addColorStop(1.0, "rgba(" + sunR + "," + sunG + "," + sunB + ", 0)");
        ctx.fillStyle = haloGrad;
        ctx.beginPath();
        ctx.arc(cx, cy, 72, 0, Math.PI * 2);
        ctx.fill();

        // Individual dynamic light streaks (one emerges as another fades)
        for (var i = 0; i < root.rays.length; i++) {
            var r = root.rays[i];
            if (isPartly && !r.isPartly) continue;

            var sVal = Math.sin(root.frame * r.speed + r.phase);
            if (sVal <= 0.005) continue;

            var intensity = Math.pow(sVal, 2.2) * rayScale;
            if (intensity < 0.01) continue;

            var curAngle = r.baseAngle + Math.sin(root.frame * r.swaySpeed + r.phase) * r.swayAmp;
            var halfW = r.widthAngle * (0.88 + 0.12 * intensity);
            var curLen = r.length * (0.82 + 0.18 * intensity);

            var a1 = curAngle - halfW;
            var a2 = curAngle + halfW;
            var innerR = 18;

            var rayGrad = ctx.createRadialGradient(cx, cy, innerR, cx, cy, curLen);
            rayGrad.addColorStop(0.00, "rgba(" + sunR + "," + sunG + "," + sunB + "," + (intensity * 0.42) + ")");
            rayGrad.addColorStop(0.35, "rgba(" + sunR + "," + sunG + "," + sunB + "," + (intensity * 0.22) + ")");
            rayGrad.addColorStop(0.70, "rgba(" + sunR + "," + sunG + "," + sunB + "," + (intensity * 0.06) + ")");
            rayGrad.addColorStop(1.00, "rgba(" + sunR + "," + sunG + "," + sunB + ", 0)");

            ctx.fillStyle = rayGrad;
            ctx.beginPath();
            ctx.moveTo(cx + Math.cos(a1) * innerR, cy + Math.sin(a1) * innerR);
            ctx.lineTo(cx + Math.cos(a1) * curLen, cy + Math.sin(a1) * curLen);
            ctx.arc(cx, cy, curLen, a1, a2, false);
            ctx.lineTo(cx + Math.cos(a2) * innerR, cy + Math.sin(a2) * innerR);
            ctx.arc(cx, cy, innerR, a2, a1, true);
            ctx.closePath();
            ctx.fill();
        }
    }

    function drawClouds(ctx, w, h, cr, cg, cb) {
        var isPartly = (root.activeKind === "partly_cloudy");
        var count = isPartly ? 4 : root.clouds.length;
        var maxAlpha = isPartly ? 0.32 : 0.40;

        // Soft, luminous cloud tint (60% blend with pure white for clear contrast)
        var wcr = Math.min(255, Math.round(cr * 0.40 + 255 * 0.60));
        var wcg = Math.min(255, Math.round(cg * 0.40 + 255 * 0.60));
        var wcb = Math.min(255, Math.round(cb * 0.40 + 255 * 0.60));

        for (var i = 0; i < count; i++) {
            var c = root.clouds[i];
            if (!c) continue;

            // Extended lifecycle envelope:
            // 0.00 -> 0.15: Smooth fade in (~4-6s)
            // 0.15 -> 0.80: Full visibility sustained float across the sky (~18-24s)
            // 0.80 -> 1.00: Smooth fade out (~5-7s)
            var lifeFactor = 0;
            if (c.life < 0.15) {
                lifeFactor = Math.sin((c.life / 0.15) * (Math.PI / 2));
            } else if (c.life > 0.80) {
                lifeFactor = Math.sin(((1.0 - c.life) / 0.20) * (Math.PI / 2));
            } else {
                lifeFactor = 1.0;
            }

            // Gentle edge fade to prevent clipping at boundaries
            var edgeFactor = 1.0;
            if (c.x < 25) {
                edgeFactor = Math.max(0, (c.x + 45) / 70);
            } else if (c.x > w - 45) {
                edgeFactor = Math.max(0, (w + 20 - c.x) / 65);
            }

            var alpha = lifeFactor * edgeFactor * maxAlpha;
            if (alpha < 0.01) continue;

            var r = 16 * c.scale;
            var x = c.x;
            var y = c.y;

            // Single unified path with clean moveTo for each circular lobe
            ctx.fillStyle = "rgba(" + wcr + "," + wcg + "," + wcb + "," + alpha + ")";
            ctx.beginPath();
            // Lobe 1: left
            ctx.moveTo(x - r * 0.70 + r * 0.58, y + r * 0.08);
            ctx.arc(x - r * 0.70, y + r * 0.08, r * 0.58, 0, Math.PI * 2);
            // Lobe 2: top main
            ctx.moveTo(x + r * 0.88, y - r * 0.32);
            ctx.arc(x, y - r * 0.32, r * 0.88, 0, Math.PI * 2);
            // Lobe 3: right
            ctx.moveTo(x + r * 0.72 + r * 0.65, y - r * 0.10);
            ctx.arc(x + r * 0.72, y - r * 0.10, r * 0.65, 0, Math.PI * 2);
            // Lobe 4: far right
            ctx.moveTo(x + r * 1.25 + r * 0.45, y + r * 0.14);
            ctx.arc(x + r * 1.25, y + r * 0.14, r * 0.45, 0, Math.PI * 2);
            // Lobe 5: flat/soft bottom
            ctx.moveTo(x + r * 0.25 + r * 0.70, y + r * 0.24);
            ctx.arc(x + r * 0.25, y + r * 0.24, r * 0.70, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    function drawRain(ctx, w, h, pr, pg, pb, cr, cg, cb) {
        // Subtle cool rain mist wash across card
        ctx.fillStyle = "rgba(" + cr + "," + cg + "," + cb + ", 0.035)";
        ctx.fillRect(0, 0, w, h);

        ctx.lineCap = "round";
        var rr = Math.round(cr * 0.70 + 180 * 0.30);
        var rg = Math.round(cg * 0.70 + 215 * 0.30);
        var rb = Math.round(cb * 0.70 + 255 * 0.30);

        for (var i = 0; i < root.rainDrops.length; i++) {
            var d = root.rainDrops[i];
            if (!d) continue;
            var dx = d.len * 0.25;
            ctx.strokeStyle = "rgba(" + rr + "," + rg + "," + rb + "," + d.alpha + ")";
            ctx.lineWidth = d.thickness;
            ctx.beginPath();
            ctx.moveTo(d.x, d.y);
            ctx.lineTo(d.x - dx, d.y + d.len);
            ctx.stroke();
        }

        // Tactile impact ripples at the bottom
        for (var j = 0; j < root.splashes.length; j++) {
            var s = root.splashes[j];
            if (!s) continue;
            ctx.strokeStyle = "rgba(" + rr + "," + rg + "," + rb + "," + (s.alpha * 0.35) + ")";
            ctx.lineWidth = 1.0;
            ctx.beginPath();
            ctx.ellipse(s.x, s.y, s.r, s.r * 0.32, 0, 0, Math.PI * 2);
            ctx.stroke();
        }

        // Thunderstorm ambient lightning flash
        if (root.weatherCode >= 200 && root.weatherCode < 300) {
            root.flash *= 0.84;
            if (root.flash < 0.02 && (root.frame % 150) === 0) root.flash = 1.0;
            if (root.flash > 0.02) {
                ctx.fillStyle = "rgba(255, 255, 255, " + (root.flash * 0.16) + ")";
                ctx.fillRect(0, 0, w, h);
            }
        }
    }

    onActiveKindChanged: {
        if (hasClouds) initClouds();
        if (hasRain) initRain();
        canvas.requestPaint();
    }

    onWidthChanged: {
        if (hasClouds && clouds.length === 0) initClouds();
        if (hasRain && rainDrops.length === 0) initRain();
        canvas.requestPaint();
    }

    onHeightChanged: {
        canvas.requestPaint();
    }

    Component.onCompleted: {
        initRays();
        initClouds();
        initRain();
    }

    Timer {
        id: animTimer
        running: root.active && root.visible && root.width > 10 && root.height > 10
        interval: 33
        repeat: true
        onTriggered: {
            root.frame++;
            if (root.hasClouds) root.stepClouds();
            if (root.hasRain) root.stepRain();
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            var cradius = root.cardRadius;
            ctx.save();
            ctx.beginPath();
            ctx.moveTo(cradius, 0);
            ctx.arcTo(w, 0, w, h, cradius);
            ctx.arcTo(w, h, 0, h, cradius);
            ctx.arcTo(0, h, 0, 0, cradius);
            ctx.arcTo(0, 0, w, 0, cradius);
            ctx.closePath();
            ctx.clip();

            var pCol = root.primaryColor;
            var pr = Math.round((pCol.r ?? 1.0) * 255);
            var pg = Math.round((pCol.g ?? 0.85) * 255);
            var pb = Math.round((pCol.b ?? 0.5) * 255);

            var cCol = root.onContainerColor;
            var cr = Math.round((cCol.r ?? 0.9) * 255);
            var cg = Math.round((cCol.g ?? 0.9) * 255);
            var cb = Math.round((cCol.b ?? 0.95) * 255);

            if (root.hasSunRays) {
                root.drawRays(ctx, w, h, pr, pg, pb);
            }

            if (root.hasClouds) {
                root.drawClouds(ctx, w, h, cr, cg, cb);
            }

            if (root.hasRain) {
                root.drawRain(ctx, w, h, pr, pg, pb, cr, cg, cb);
            }

            ctx.restore();
        }
    }
}
