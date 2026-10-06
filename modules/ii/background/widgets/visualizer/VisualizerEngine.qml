import QtQuick
import qs

/*
 * Turns the raw cava levels into what the shader styles draw: smoothed levels
 * (fast attack, slow release), falling peaks, a beat pulse and a playback fade.
 * Ticks only while there is something to animate, and emits frame() after each step.
 */
Item {
    id: root
    visible: false

    property bool active: true
    property real sensitivity: 1
    property real maxValue: 1000

    readonly property int maxBands: 52
    readonly property list<real> raw: GlobalStates.visualizerPoints
    property int bandCount: 0
    property real time: 0
    property real bass: 0
    property real fade: 0
    // Mutated in place every frame, read them from frame()
    readonly property var levels: new Array(maxBands).fill(0)
    readonly property var peaks: new Array(maxBands).fill(0)

    signal frame()

    property real lastSignal: 0
    property real bassAverage: 0
    readonly property var peakHold: new Array(maxBands).fill(0)

    // Ryoku-inspired Adaptive Governor & Budget State
    property real govOverrun: 1.0
    property int govTier: 0          // 0 = 60fps (full), 1 = 30fps, 2 = 20fps
    property real govSince: 0
    property int frameSkipCounter: 0

    onRawChanged: {
        if (!root.active) return;
        if (root.raw.length > 0) root.bandCount = Math.min(root.raw.length, root.maxBands);
        for (let i = 0; i < root.raw.length; i++) {
            if (root.raw[i] > 0) {
                root.lastSignal = Date.now();
                if (!ticker.running) {
                    ticker.running = true;
                }
                return;
            }
        }
    }

    Component.onCompleted: {
        if (root.raw.length > 0) {
            root.bandCount = Math.min(root.raw.length, root.maxBands);
            for (let i = 0; i < root.raw.length; i++) {
                if (root.raw[i] > 0) {
                    root.lastSignal = Date.now();
                    ticker.running = true;
                    return;
                }
            }
        }
    }

    function step(dt) {
        const now = Date.now();
        // 250ms silence threshold for snappy silence detection
        const playing = (now - root.lastSignal < 250);

        // Adaptive Governor: monitor frame overrun and throttle FPS under heavy system load
        const targetDt = 1.0 / 60.0;
        const ratio = Math.min(3.0, dt > 0 ? dt / targetDt : 1.0);
        root.govOverrun += (ratio - root.govOverrun) * 0.08;
        if (now - root.govSince > 2500) {
            if (root.govOverrun > 1.35 && root.govTier < 2) {
                root.govTier++;
                root.govSince = now;
            } else if (root.govOverrun < 1.12 && root.govTier > 0) {
                root.govTier--;
                root.govSince = now;
            }
        }

        // Paced frame skip when throttled by governor
        if (root.govTier > 0) {
            root.frameSkipCounter = (root.frameSkipCounter + 1) % (root.govTier + 1);
            if (root.frameSkipCounter !== 0) return;
        }

        const src = root.raw;
        root.time += dt;
        root.fade += ((playing ? 1 : 0) - root.fade) * Math.min(1, dt * (playing ? 8 : 4));

        let maxLvl = 0;
        let bassNow = 0;
        for (let i = 0; i < root.maxBands; i++) {
            const target = playing && i < src.length ? Math.min(1, src[i] / root.maxValue * root.sensitivity) : 0;
            const level = root.levels[i];
            root.levels[i] = level + (target - level) * Math.min(1, dt * (target > level ? 42 : 18));
            if (root.levels[i] > maxLvl) maxLvl = root.levels[i];

            if (root.levels[i] >= root.peaks[i]) {
                root.peaks[i] = root.levels[i];
                root.peakHold[i] = 0.08;
            } else if (root.peakHold[i] > 0) {
                root.peakHold[i] -= dt;
            } else {
                root.peaks[i] = Math.max(root.levels[i], root.peaks[i] - dt * 2.0);
            }
            if (i < 4) bassNow += target / 4;
        }

        // A beat is bass energy rising well above its recent average
        root.bassAverage += (bassNow - root.bassAverage) * Math.min(1, dt * 2.5);
        if (bassNow > root.bassAverage * 1.25 + 0.03 && bassNow > 0.20)
            root.bass = Math.min(1, root.bass + (bassNow - root.bassAverage) * 3.0);
        root.bass *= Math.exp(-dt * 6.0);

        root.frame();

        // Automatic Silence Freeze: zero out bands and halt FrameAnimation completely
        if (!playing && maxLvl < 0.003 && root.fade < 0.005) {
            root.fade = 0;
            for (let j = 0; j < root.maxBands; j++) {
                root.levels[j] = 0;
                root.peaks[j] = 0;
            }
            ticker.running = false;
        }
    }

    FrameAnimation {
        id: ticker
        running: false
        onTriggered: root.step(Math.min(frameTime, 0.1))
    }
}
