pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common

Item {
    id: root
    anchors.fill: parent
    z: -1

    required property Item leftSection
    required property Item centerSection
    required property Item rightSection

    // Configuration
    readonly property bool fillerEnabled: (Config.options?.bar?.islandFiller?.enable ?? true)
        && (Config.options?.bar?.islandFiller?.style !== "none")
        && (Config.options.bar.cornerStyle === 2 || Config.options?.bar.borderless === "separated" || !Config.options.bar.showBackground)
    readonly property string fillerStyle: Config.options?.bar?.islandFiller?.style ?? "waves"
    readonly property real fillerOpacity: Config.options?.bar?.islandFiller?.opacity ?? 0.85

    // Matugen theme colors
    readonly property color primaryColor: Appearance.colors.colPrimary
    readonly property color secondaryColor: Appearance.colors.colSecondary
    readonly property color tertiaryColor: Appearance.colors.colTertiary
    readonly property vector4d vecColPrimary: Qt.vector4d(primaryColor.r, primaryColor.g, primaryColor.b, 1.0)
    readonly property vector4d vecColSecondary: Qt.vector4d(secondaryColor.r, secondaryColor.g, secondaryColor.b, 1.0)
    readonly property vector4d vecColTertiary: Qt.vector4d(tertiaryColor.r, tertiaryColor.g, tertiaryColor.b, 1.0)

    // Audio energy derived from visualizer points
    readonly property real audioEnergy: {
        const pts = GlobalStates.visualizerPoints;
        if (!pts || pts.length === 0) return 0;
        let sum = 0;
        const len = Math.min(pts.length, 16);
        for (let i = 0; i < len; i++) sum += (pts[i] || 0);
        return Math.min(1.0, (sum / len) / 60.0);
    }
    readonly property bool hasAudio: audioEnergy > 0.05

    // Clock driver: paced at 30 fps idle, 60 fps under audio playback
    property real time: 0
    Timer {
        id: clock
        interval: root.hasAudio ? 16 : 33
        repeat: true
        running: root.visible && root.fillerEnabled && (root.fillerStyle !== "bridge" && root.fillerStyle !== "none")
        onTriggered: root.time += interval / 1000.0
    }

    // Dynamic Island / Center Presence
    readonly property bool hasCenter: centerSection && centerSection.width > 0

    // Gap 1: Left section -> Center section
    readonly property real gap1X: (leftSection && leftSection.width > 0) ? (leftSection.x + leftSection.width) : 0
    readonly property real gap1End: hasCenter ? centerSection.x : 0
    readonly property real gap1W: Math.max(0, gap1End - gap1X)
    readonly property bool gap1Active: fillerEnabled && hasCenter && (gap1W > 12)

    // Gap 2: Center section -> Right section
    readonly property real gap2X: hasCenter ? (centerSection.x + centerSection.width) : 0
    readonly property real gap2End: (rightSection && rightSection.width > 0) ? rightSection.x : parent.width
    readonly property real gap2W: Math.max(0, gap2End - gap2X)
    readonly property bool gap2Active: fillerEnabled && hasCenter && (gap2W > 12)

    // Fallback Span (when Center island is hidden / not configured)
    readonly property real spanX: (leftSection && leftSection.width > 0) ? (leftSection.x + leftSection.width) : 0
    readonly property real spanEnd: (rightSection && rightSection.width > 0) ? rightSection.x : parent.width
    readonly property real spanW: Math.max(0, spanEnd - spanX)
    readonly property bool spanActive: fillerEnabled && !hasCenter && (spanW > 12)

    // Bridge dimensions
    readonly property real bridgeH: Math.max(14, parent.height - 14)

    // Mode selection for Ryoku stream shader
    readonly property real streamModeNumber: {
        switch (root.fillerStyle) {
            case "stream":   return 1.0;
            case "surge":    return 2.0;
            case "bolt":     return 3.0;
            case "spark":    return 4.0;
            case "transfer": return 5.0;
            case "collider": return 6.0;
            default:         return 1.0;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STYLE: "waves" (Harmonic flowing ribbons with stardust particles)
    // ─────────────────────────────────────────────────────────────────────────
    ShaderEffect {
        id: wavesGap1
        visible: root.fillerStyle === "waves" && root.gap1Active
        x: root.gap1X
        y: 0
        width: root.gap1W
        height: parent.height
        opacity: root.fillerOpacity

        property real time: root.time
        property real aud: root.audioEnergy
        property real gapX: root.gap1X
        property real gapW: width
        property real gapH: height
        property real gapIndex: 0.0
        property real styleMode: 0.0
        property vector4d colPrimary: root.vecColPrimary
        property vector4d colSecondary: root.vecColSecondary
        property vector4d colTertiary: root.vecColTertiary

        fragmentShader: "shaders/wave_stream.frag.qsb"
    }

    ShaderEffect {
        id: wavesGap2
        visible: root.fillerStyle === "waves" && root.gap2Active
        x: root.gap2X
        y: 0
        width: root.gap2W
        height: parent.height
        opacity: root.fillerOpacity

        property real time: root.time
        property real aud: root.audioEnergy
        property real gapX: root.gap2X
        property real gapW: width
        property real gapH: height
        property real gapIndex: 1.0
        property real styleMode: 0.0
        property vector4d colPrimary: root.vecColPrimary
        property vector4d colSecondary: root.vecColSecondary
        property vector4d colTertiary: root.vecColTertiary

        fragmentShader: "shaders/wave_stream.frag.qsb"
    }

    ShaderEffect {
        id: wavesSpan
        visible: root.fillerStyle === "waves" && root.spanActive
        x: root.spanX
        y: 0
        width: root.spanW
        height: parent.height
        opacity: root.fillerOpacity

        property real time: root.time
        property real aud: root.audioEnergy
        property real gapX: root.spanX
        property real gapW: width
        property real gapH: height
        property real gapIndex: 0.0
        property real styleMode: 0.0
        property vector4d colPrimary: root.vecColPrimary
        property vector4d colSecondary: root.vecColSecondary
        property vector4d colTertiary: root.vecColTertiary

        fragmentShader: "shaders/wave_stream.frag.qsb"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STYLE: "stream", "bolt", "surge" (Ryoku Fragment Shader modes)
    // ─────────────────────────────────────────────────────────────────────────
    ShaderEffect {
        id: streamGap1
        visible: (root.fillerStyle === "stream" || root.fillerStyle === "bolt" || root.fillerStyle === "surge" || root.fillerStyle === "spark" || root.fillerStyle === "transfer" || root.fillerStyle === "collider") && root.gap1Active
        x: root.gap1X
        y: 0
        width: root.gap1W
        height: parent.height
        opacity: root.fillerOpacity

        property real time: root.time
        property real aud: root.audioEnergy
        property real gapX: root.gap1X
        property real gapW: width
        property real gapH: height
        property real gapIndex: 0.0
        property real mode: root.streamModeNumber
        property vector4d seal: root.vecColPrimary

        fragmentShader: "shaders/stream.frag.qsb"
    }

    ShaderEffect {
        id: streamGap2
        visible: (root.fillerStyle === "stream" || root.fillerStyle === "bolt" || root.fillerStyle === "surge" || root.fillerStyle === "spark" || root.fillerStyle === "transfer" || root.fillerStyle === "collider") && root.gap2Active
        x: root.gap2X
        y: 0
        width: root.gap2W
        height: parent.height
        opacity: root.fillerOpacity

        property real time: root.time
        property real aud: root.audioEnergy
        property real gapX: root.gap2X
        property real gapW: width
        property real gapH: height
        property real gapIndex: 1.0
        property real mode: root.streamModeNumber
        property vector4d seal: root.vecColPrimary

        fragmentShader: "shaders/stream.frag.qsb"
    }

    ShaderEffect {
        id: streamSpan
        visible: (root.fillerStyle === "stream" || root.fillerStyle === "bolt" || root.fillerStyle === "surge" || root.fillerStyle === "spark" || root.fillerStyle === "transfer" || root.fillerStyle === "collider") && root.spanActive
        x: root.spanX
        y: 0
        width: root.spanW
        height: parent.height
        opacity: root.fillerOpacity

        property real time: root.time
        property real aud: root.audioEnergy
        property real gapX: root.spanX
        property real gapW: width
        property real gapH: height
        property real gapIndex: 0.0
        property real mode: root.streamModeNumber
        property vector4d seal: root.vecColPrimary

        fragmentShader: "shaders/stream.frag.qsb"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STYLE: "bridge" (Physical Dock Plate connector)
    // ─────────────────────────────────────────────────────────────────────────
    Rectangle {
        id: bridgeGap1
        visible: root.fillerStyle === "bridge" && root.gap1Active
        x: root.gap1X - 6
        y: Math.round((parent.height - root.bridgeH) / 2)
        width: root.gap1W + 12
        height: root.bridgeH
        radius: root.bridgeH / 2
        color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, root.fillerOpacity * 0.5)
        border.width: 1
        border.color: Qt.rgba(Appearance.colors.colLayer0Border.r, Appearance.colors.colLayer0Border.g, Appearance.colors.colLayer0Border.b, 0.3)

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: 1
            color: root.primaryColor
            opacity: root.hasAudio ? 0.28 : 0.08
            visible: width > 10
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }

    Rectangle {
        id: bridgeGap2
        visible: root.fillerStyle === "bridge" && root.gap2Active
        x: root.gap2X - 6
        y: Math.round((parent.height - root.bridgeH) / 2)
        width: root.gap2W + 12
        height: root.bridgeH
        radius: root.bridgeH / 2
        color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, root.fillerOpacity * 0.5)
        border.width: 1
        border.color: Qt.rgba(Appearance.colors.colLayer0Border.r, Appearance.colors.colLayer0Border.g, Appearance.colors.colLayer0Border.b, 0.3)

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: 1
            color: root.primaryColor
            opacity: root.hasAudio ? 0.28 : 0.08
            visible: width > 10
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }

    Rectangle {
        id: bridgeSpan
        visible: root.fillerStyle === "bridge" && root.spanActive
        x: root.spanX - 6
        y: Math.round((parent.height - root.bridgeH) / 2)
        width: root.spanW + 12
        height: root.bridgeH
        radius: root.bridgeH / 2
        color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, root.fillerOpacity * 0.5)
        border.width: 1
        border.color: Qt.rgba(Appearance.colors.colLayer0Border.r, Appearance.colors.colLayer0Border.g, Appearance.colors.colLayer0Border.b, 0.3)

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: 1
            color: root.primaryColor
            opacity: root.hasAudio ? 0.28 : 0.08
            visible: width > 10
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }
}
