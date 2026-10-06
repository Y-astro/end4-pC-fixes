import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool mirrored: false

    // Target dimensions for the tacet mark inside the bar pill
    property real visualizerWidth: 105
    property real visualizerHeight: 30

    implicitWidth: vertical
        ? Appearance.sizes.verticalBarWidth
        : (isMaterial ? visualizerWidth + 20 : visualizerWidth)
    implicitHeight: vertical
        ? (isMaterial ? visualizerWidth + 20 : visualizerWidth)
        : Appearance.sizes.barHeight

    transform: Scale {
        xScale: !root.vertical && root.mirrored ? -1 : 1
        origin.x: root.width / 2
    }

    Item {
        id: container
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0
        width: root.visualizerWidth
        height: root.visualizerHeight
        rotation: root.vertical ? 90 : 0

        // Subtle floating bob
        SequentialAnimation on anchors.verticalCenterOffset {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: -1.5; duration: 1800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.5; duration: 1800; easing.type: Easing.InOutSine }
        }

        transform: Scale {
            id: breathScale
            origin.x: container.width / 2
            origin.y: container.height / 2

            // Vertical needle breathing: stretches and flexes
            SequentialAnimation on yScale {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 1.08; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.92; duration: 1500; easing.type: Easing.InOutSine }
            }

            // Horizontal breathing: subtle counter-expansion
            SequentialAnimation on xScale {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 1.04; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.96; duration: 2000; easing.type: Easing.InOutSine }
            }
        }

        // Texture provider: high-resolution SVG render of the authentic WuWa Tacet Mark
        Image {
            id: tacetSource
            source: Qt.resolvedUrl("../../../assets/icons/tacet-mark.svg")
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 496
            sourceSize.height: 165
            smooth: true
            mipmap: true
        }

        ShaderEffectSource {
            id: tacetSourceItem
            sourceItem: tacetSource
            hideSource: true
            live: false
        }

        // Layer 1: Soft luminous aura / glow behind the tacet mark
        Image {
            id: auraImage
            source: Qt.resolvedUrl("../../../assets/icons/tacet-mark.svg")
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 496
            sourceSize.height: 165
            smooth: true
        }

        ColorOverlay {
            id: auraOverlay
            anchors.fill: auraImage
            source: auraImage
            color: Appearance.colors.colPrimary
            scale: 1.08

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 0.55; duration: 1400; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.18; duration: 1400; easing.type: Easing.InOutQuad }
            }
        }

        FastBlur {
            anchors.fill: auraOverlay
            source: auraOverlay
            radius: 8
            opacity: 0.8
        }

        // Layer 2: Sharp animated tacet mark with resonant energy wave & highlight crest
        ShaderEffect {
            id: animatedShader
            anchors.fill: parent

            property var source: tacetSourceItem
            property real time: 0.0
            property vector2d resolution: Qt.vector2d(width, height)
            property color colorPrimary: Appearance.colors.colPrimary
            property color colorAccent: Appearance.m3colors.m3tertiary

            fragmentShader: Qt.resolvedUrl("shaders/tacet_animated.frag.qsb")

            FrameAnimation {
                id: ticker
                running: true
                onTriggered: animatedShader.time += Math.min(frameTime, 0.1)
            }
        }
    }
}