pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

ButtonMouseArea {
    id: root

    WorkspaceModel {
        id: wsModel
        screen: root.QsWindow.window?.screen
    }

    property bool vertical: Config.options.bar.vertical
    property bool superPressAndHeld: false // Relevant modifications at bottom of file

    property real workspaceButtonWidth: Config.options.bar.cornerStyle === 3 ? 30 : 26
    property real activeWorkspaceMargin: 2
    property real activeWorkspaceSize: workspaceButtonWidth - activeWorkspaceMargin * 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: wsModel.activeVisibleIndex
    property real specialTextSize: workspaceButtonWidth * 0.5

    readonly property bool isPacmanStyle: (Config.options?.bar.workspaces.indicatorStyle ?? "dot") === "pacman"

    // Pacman travel state
    property real pacmanTravelPos: 0
    property real pacmanTravelFromPos: 0
    property real pacmanTravelTargetPos: 0
    property int pacmanTravelDirection: 1
    property int pacmanFacingDirection: 1
    property int pacmanTravelSteps: 1
    property bool pacmanTraveling: false
    property real pacmanMouthClosure: 0
    property real pacmanEatProgress: 0
    property int pacmanTargetWorkspaceId: -1
    property int pacmanSourceWorkspaceId: -1
    property int pacmanLastFocusedWorkspaceId: -1

    readonly property int pacmanTravelDuration: Math.min(720, 280 + pacmanTravelSteps * 90)
    readonly property int pacmanBiteCount: Math.max(3, Math.min(6, pacmanTravelSteps + 2))
    readonly property int pacmanBiteHalfDuration: Math.max(50, Math.round(pacmanTravelDuration / (pacmanBiteCount * 2)))
    readonly property real pacmanMaxMouthClosure: 0.82
    readonly property int pacmanEatDuration: 220
    readonly property int pacmanEatLeadIn: Math.max(0, pacmanTravelDuration - pacmanEatDuration)

    function pacmanCellIndex(id) {
        if (!wsModel.visibleWorkspaces) return -1;
        for (let i = 0; i < wsModel.visibleCount; i++) {
            if (wsModel.visibleWorkspaces[i]?.id === id) return i;
        }
        return -1;
    }
    function pacmanCenterPos(index) {
        return (index + 0.5) * root.workspaceButtonWidth;
    }
    function finishPacmanTravel() {
        pacmanTraveling = false;
        pacmanMouthClosure = 0;
        pacmanEatProgress = 0;
        pacmanTargetWorkspaceId = -1;
    }
    function resetPacmanTravel() {
        pacmanTravel.stop();
        finishPacmanTravel();
        pacmanLastFocusedWorkspaceId = wsModel.activeNumber;
    }
    function beginPacmanTravel(sourceId, targetId) {
        if (!root.isPacmanStyle || wsModel.activeNumber !== targetId) {
            resetPacmanTravel();
            return;
        }
        var sourceIndex = pacmanCellIndex(sourceId);
        var targetIndex = pacmanCellIndex(targetId);
        if (sourceIndex < 0 || targetIndex < 0 || sourceIndex === targetIndex) {
            finishPacmanTravel();
            return;
        }
        var targetPos = pacmanCenterPos(targetIndex);
        var sourcePos = pacmanTraveling ? pacmanTravelPos : pacmanCenterPos(sourceIndex);

        pacmanTravel.stop();
        pacmanTravelFromPos = sourcePos;
        pacmanTravelTargetPos = targetPos;
        pacmanTravelPos = sourcePos;
        pacmanTravelDirection = targetPos >= sourcePos ? 1 : -1;
        pacmanFacingDirection = pacmanTravelDirection;
        pacmanTravelSteps = Math.max(1, Math.abs(targetIndex - sourceIndex));
        pacmanTargetWorkspaceId = targetId;
        pacmanSourceWorkspaceId = sourceId;
        pacmanEatProgress = 0;
        pacmanMouthClosure = 0;
        pacmanTraveling = true;
        pacmanTravel.restart();
    }
    function observePacmanFocus() {
        var targetId = wsModel.activeNumber;
        if (targetId < 1) return;
        if (!root.isPacmanStyle || pacmanLastFocusedWorkspaceId < 1) {
            resetPacmanTravel();
            pacmanLastFocusedWorkspaceId = targetId;
            return;
        }
        if (targetId === pacmanLastFocusedWorkspaceId) return;
        var sourceId = pacmanLastFocusedWorkspaceId;
        pacmanLastFocusedWorkspaceId = targetId;
        Qt.callLater(function() { root.beginPacmanTravel(sourceId, targetId); });
    }

    onIsPacmanStyleChanged: {
        root.resetPacmanTravel();
        pacmanLastFocusedWorkspaceId = wsModel.activeNumber;
    }

    Component.onCompleted: {
        pacmanLastFocusedWorkspaceId = wsModel.activeNumber;
    }

    Connections {
        target: wsModel
        function onActiveNumberChanged() {
            root.observePacmanFocus();
        }
    }

    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
    readonly property real barThickness: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
    implicitWidth: vertical ? barThickness : occupiedIndicators.implicitWidth
    implicitHeight: vertical ? occupiedIndicators.implicitHeight : barThickness

    property real specialBlur: (wsModel.specialWorkspaceActive && !containsMouse) ? 1 : 0
    Behavior on specialBlur {
        animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
    }

    // Interactions
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    property int hoverIndex: {
        const position = root.vertical ? mouseY : mouseX;
        const idx = Math.floor(position / root.workspaceButtonWidth);
        return Math.max(0, Math.min(idx, wsModel.visibleCount - 1));
    }

    function switchWorkspaceToHovered() {
        if (wsModel.visibleWorkspaces && wsModel.visibleWorkspaces[hoverIndex]) {
            WM.switchWorkspace(wsModel.visibleWorkspaces[hoverIndex].id);
        }
    }
    onPressed: mouse => {
        if (mouse.button == Qt.LeftButton)
            switchWorkspaceToHovered();
        else if (mouse.button == Qt.RightButton)
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }
    onWheel: event => {
        if (event.angleDelta.y < 0)
            WM.switchWorkspaceRelative("next");
        else if (event.angleDelta.y > 0)
            WM.switchWorkspaceRelative("prev");
    }

    // Indications
    Item {
        id: regularWorkspaces
        anchors.fill: parent

        scale: 1 - 0.08 * root.specialBlur
        layer.smooth: true
        layer.enabled: root.specialBlur > 0
        layer.effect: MultiEffect {
            brightness: -0.1 * root.specialBlur
            blurEnabled: true
            blur: root.specialBlur
            blurMax: 32
        }

        /////////////////// Occupied indicators ///////////////////
        StyledRectangle {
            id: occupiedIndicatorsBg
            anchors.fill: parent
            contentLayer: StyledRectangle.ContentLayer.Group
            color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
            visible: false
        }

        WorkspaceLayout {
            id: occupiedIndicators
            anchors.centerIn: parent

            layer.enabled: true
            visible: false

            Repeater {
                model: wsModel.visibleCount
                delegate: Item {
                    id: wsBg
                    required property int index
                    readonly property var wsData: wsModel.visibleWorkspaces[index]
                    readonly property int wsId: wsData ? wsData.id : 0
                    property bool currentOccupied: (wsData ? wsData.occupied : false) && wsId != wsModel.fakeWorkspace
                    property bool previousOccupied: index > 0 && wsModel.visibleWorkspaces[index - 1]?.occupied && (wsModel.visibleWorkspaces[index - 1]?.id === wsId - 1) && (wsId - 1) != wsModel.fakeWorkspace
                    property bool nextOccupied: index < wsModel.visibleCount - 1 && wsModel.visibleWorkspaces[index + 1]?.occupied && (wsModel.visibleWorkspaces[index + 1]?.id === wsId + 1) && (wsId + 1) != wsModel.fakeWorkspace
                    implicitWidth: root.workspaceButtonWidth
                    implicitHeight: root.workspaceButtonWidth

                    // The idea: over-stretch to occupied sides, animate this for a smooth transition.
                    //           masking already prevents weird overlaps
                    Pill {
                        property real undirectionalWidth: root.workspaceButtonWidth * wsBg.currentOccupied
                        property real undirectionalLength: root.workspaceButtonWidth * (1 + 0.5 * wsBg.previousOccupied + 0.5 * wsBg.nextOccupied) * currentOccupied
                        property real undirectionalOffset: (!wsBg.currentOccupied ? 0.5 : -0.5 * wsBg.previousOccupied) * root.workspaceButtonWidth
                        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        x: root.vertical ? 0 : undirectionalOffset
                        y: root.vertical ? undirectionalOffset : 0
                        implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
                        implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

                        Behavior on undirectionalWidth {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalLength {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalOffset {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }
                }
            }
        }

        MaskMultiEffect {
            id: occupiedIndicatorsMultiEffect
            z: 1
            anchors.centerIn: parent
            implicitWidth: occupiedIndicators.implicitWidth
            implicitHeight: occupiedIndicators.implicitHeight
            source: occupiedIndicatorsBg
            maskSource: occupiedIndicators
            visible: !root.isPacmanStyle
        }

        /////////////////// Active indicator ///////////////////
        TrailingIndicator {
            id: activeIndicator
            anchors.fill: parent
            z: 2

            index: wsModel.activeVisibleIndex
            visible: !root.isPacmanStyle
        }

        /////////////////// Hover ///////////////////
        TrailingIndicator {
            id: interactionIndicator
            z: 3
            index: root.containsMouse ? root.hoverIndex : wsModel.activeVisibleIndex
            color: "transparent"
            visible: !root.isPacmanStyle
            StateOverlay {
                id: hoverOverlay
                anchors.fill: interactionIndicator.indicatorRectangle
                radius: root.activeWorkspaceSize / 2
                hover: root.containsMouse
                press: root.containsPress
                drag: true // There are too many layers so we need to force this to be a lil more opaque
                contentColor: Appearance.colors.colPrimary
            }
        }

        /////////////////// Numbers ///////////////////
        WorkspaceLayout {
            id: numbersGrid
            z: 4
            layer.enabled: !root.isPacmanStyle // For the masking

            Repeater {
                model: wsModel.visibleCount
                delegate: NumberWorkspaceItem {}
            }
        }
        Colorizer {
            z: 5
            anchors.fill: numbersGrid
            colorizationColor: Appearance.colors.colOnPrimary
            sourceColor: Appearance.colors.colOnSecondaryContainer

            source: activeIndicator
            maskEnabled: true
            maskSource: numbersGrid

            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
            visible: !root.isPacmanStyle
        }

        /////////////////// App icons ///////////////////
        WorkspaceLayout {
            id: appsGrid
            z: 6
            visible: !root.isPacmanStyle

            Repeater {
                model: wsModel.visibleCount
                delegate: WorkspaceItem {
                    id: wsApp
                    property var wsData: wsModel.visibleWorkspaces[index]
                    property var biggestWindow: wsData ? wsData.biggestWindow : null
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    AppIcon {
                        id: appIcon
                        property real cornerMargin: (!root.superPressAndHeld && Config.options?.bar.workspaces.showAppIcons && wsApp.biggestWindow) ? (root.workspaceButtonWidth - root.workspaceIconSize) / 2 : root.workspaceIconMarginShrinked
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                            bottomMargin: (parent.implicitHeight - root.workspaceButtonWidth) / 2 + cornerMargin
                            rightMargin: (parent.implicitWidth - root.workspaceButtonWidth) / 2 + cornerMargin
                        }

                        animated: !wsApp.biggestWindow // Prevent the "image-missing" icon
                        visible: false // Prevent dupe: the colorizer already copies the icon

                        source: wsApp.mainAppIconSource
                        implicitSize: NumberUtils.roundToEven(root.workspaceIconSize)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on cornerMargin {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }

                    Circle {
                        id: iconMask
                        visible: false
                        layer.enabled: true
                        diameter: appIcon.implicitSize
                    }

                    Loader { // Somehow putting this multieffect in a loader prevents it from not showing up
                        id: colorizer
                        anchors.fill: appIcon
                        sourceComponent: Colorizer {
                            implicitWidth: appIcon.implicitWidth
                            implicitHeight: appIcon.implicitHeight
                            colorizationColor: Appearance.m3colors.darkmode ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                            colorization: Config.options.bar.workspaces.monochromeIcons ? 0.8 : 0.5
                            brightness: 0
                            source: appIcon

                            opacity: !Config.options?.bar.workspaces.showAppIcons ? 0 : (wsApp.biggestWindow && !root.superPressAndHeld && Config.options?.bar.workspaces.showAppIcons) ? 1 : wsApp.biggestWindow ? root.workspaceIconOpacityShrinked : 0
                            visible: opacity > 0
                            scale: ((!root.superPressAndHeld && Config.options?.bar.workspaces.showAppIcons) ? root.workspaceIconSize : root.workspaceIconSizeShrinked) / root.workspaceIconSize

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                            }

                            maskEnabled: true
                            maskSource: iconMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }
                    }
                }
            }
        }

        /////////////////// Pacman Traveling Runner ///////////////////
        Item {
            id: pacmanRunner
            visible: root.isPacmanStyle && root.pacmanTraveling
            z: 10
            x: !root.vertical ? Math.round(root.pacmanTravelPos - width / 2) : Math.round((parent.width - width) / 2)
            y: root.vertical ? Math.round(root.pacmanTravelPos - height / 2) : Math.round((parent.height - height) / 2)
            width: root.workspaceButtonWidth
            height: root.workspaceButtonWidth

            Item {
                id: pacmanRunnerVisual
                anchors.fill: parent
                transform: Scale {
                    origin.x: pacmanRunnerVisual.width / 2
                    origin.y: pacmanRunnerVisual.height / 2
                    xScale: !root.vertical ? root.pacmanTravelDirection : 1
                    yScale: root.vertical ? root.pacmanTravelDirection : 1
                }

                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF0BAF)
                    color: Appearance.colors.colPrimary
                    font.family: Appearance.font.family.iconNerd || "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(root.workspaceButtonWidth * 0.58)
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                Canvas {
                    id: pacmanMouthFill
                    anchors.centerIn: parent
                    width: Math.round(root.workspaceButtonWidth * 0.65)
                    height: width
                    property real closure: root.pacmanMouthClosure
                    property color fillColor: Appearance.colors.colPrimary

                    onClosureChanged: requestPaint()
                    onFillColorChanged: requestPaint()
                    onPaint: {
                        var context = getContext("2d")
                        var centerX = width / 2
                        var centerY = height / 2
                        var radius = Math.min(width, height) * 0.40
                        var angle = 0.70 * Math.max(0, Math.min(1, closure))
                        context.clearRect(0, 0, width, height)
                        if (angle <= 0.001) return
                        context.fillStyle = String(fillColor)
                        context.beginPath()
                        context.moveTo(centerX, centerY)
                        context.arc(centerX, centerY, radius, -angle, angle, false)
                        context.closePath()
                        context.fill()
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: pacmanTravel
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "pacmanTravelPos"
                from: root.pacmanTravelFromPos
                to: root.pacmanTravelTargetPos
                duration: root.pacmanTravelDuration
                easing.type: Easing.InOutSine
            }

            SequentialAnimation {
                loops: root.pacmanBiteCount
                NumberAnimation {
                    target: root
                    property: "pacmanMouthClosure"
                    from: 0
                    to: root.pacmanMaxMouthClosure
                    duration: root.pacmanBiteHalfDuration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: root
                    property: "pacmanMouthClosure"
                    from: root.pacmanMaxMouthClosure
                    to: 0
                    duration: root.pacmanBiteHalfDuration
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: root.pacmanEatLeadIn }
                NumberAnimation {
                    target: root
                    property: "pacmanEatProgress"
                    from: 0
                    to: 1
                    duration: root.pacmanEatDuration
                    easing.type: Easing.InCubic
                }
            }
        }

        ScriptAction { script: root.finishPacmanTravel() }
    }

    FadeLoader {
        anchors.centerIn: parent
        shown: wsModel.specialWorkspaceActive
        scale: 0.8 + 0.2 * root.specialBlur

        opacity: root.specialBlur
        Behavior on opacity {} // Don't animate, as specialBlur is already animated

        sourceComponent: Pill {
            anchors.centerIn: parent
            property real undirectionalWidth: root.activeWorkspaceSize
            property real undirectionalLength: {
                const base = root.workspaceButtonWidth * Math.min(1.35, wsModel.shownCount); // Who tf only configures only 2 workspaces shown anyway?
                if (root.vertical)
                    return base;
                return specialWsText.implicitWidth + undirectionalWidth;
            }
            color: Appearance.colors.colPrimary

            implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
            implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

            StyledText {
                id: specialWsText
                anchors.centerIn: parent
                text: (!root.vertical ? wsModel.specialWorkspaceName : "S")
                color: Appearance.colors.colOnPrimary
                font.pixelSize: root.specialTextSize
            }

            Behavior on undirectionalLength {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
        }
    }

    /////////////////// Super key press handling ///////////////////
    Timer {
        id: superPressAndHeldTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.superPressAndHeld = true;
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable)
                return;
            if (GlobalStates.superDown)
                superPressAndHeldTimer.restart();
            else {
                superPressAndHeldTimer.stop();
                root.superPressAndHeld = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() {
            superPressAndHeldTimer.stop();
        }
    }

    component WorkspaceLayout: Box {
        anchors {
            top: !root.vertical ? parent.top : undefined
            bottom: !root.vertical ? parent.bottom : undefined
            left: root.vertical ? parent.left : undefined
            right: root.vertical ? parent.right : undefined
        }

        rowSpacing: 0
        columnSpacing: 0
        vertical: root.vertical
    }

    component WorkspaceItem: Item {
        required property int index
        readonly property var wsData: wsModel.visibleWorkspaces[index]
        readonly property int wsId: wsData ? wsData.id : (index + 1)
        implicitWidth: root.vertical ? root.barThickness : root.workspaceButtonWidth
        implicitHeight: root.vertical ? root.workspaceButtonWidth : root.barThickness
    }

    component NumberWorkspaceItem: WorkspaceItem {
        id: wsNum
        property var wsData: wsModel.visibleWorkspaces[index]
        property int wsId: wsData ? wsData.id : (index + 1)
        property bool isFocused: wsNum.wsId === wsModel.activeNumber
        property bool isOccupied: (wsData ? wsData.occupied : false) && wsNum.wsId !== wsModel.fakeWorkspace
        property bool hasBiggestWindow: !!(wsData ? wsData.biggestWindow : null)
        property color contentColor: ((wsData ? wsData.occupied : false) && wsId !== wsModel.fakeWorkspace) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1Inactive
        property bool showingNumbers: {
            if (root.isPacmanStyle)
                return false;
            if (root.superPressAndHeld)
                return true;
            if (GlobalStates.screenLocked)
                return false;
            if (Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !wsNum.hasBiggestWindow))
                return true;
            return false;
        }

        FadeLoader {
            shown: !wsNum.showingNumbers
            anchors.centerIn: parent
            Loader {
                anchors.centerIn: parent
                sourceComponent: root.isPacmanStyle ? pacmanComponent : ((Config.options?.bar.workspaces.indicatorStyle ?? "dot") === "icon" ? iconComponent : dotComponent)

                Component {
                    id: pacmanComponent
                    PacmanMarker {
                        anchors.centerIn: parent
                        glyphSize: Math.round(root.workspaceButtonWidth * 0.58)
                        pelletSize: Math.round(root.workspaceButtonWidth * 0.20)
                        focused: wsNum.isFocused && !(root.pacmanTraveling && wsNum.wsId === root.pacmanTargetWorkspaceId)
                        occupied: wsNum.isOccupied
                        hovered: root.containsMouse && root.hoverIndex === wsNum.index
                        facingDirection: root.pacmanFacingDirection
                        eatProgress: (root.pacmanTraveling && wsNum.wsId === root.pacmanTargetWorkspaceId)
                            ? root.pacmanEatProgress : 0
                        eatDirection: root.pacmanTravelDirection
                        isVertical: root.vertical
                        activeColor: Appearance.colors.colPrimary
                        occupiedColor: Appearance.colors.colPrimary
                        emptyColor: Appearance.colors.colPrimary
                        hoverColor: Appearance.colors.colPrimaryHover
                    }
                }

                Component {
                    id: dotComponent
                    Circle {
                        anchors.centerIn: parent
                        diameter: root.workspaceButtonWidth * 0.18
                        color: wsNum.contentColor
                    }
                }

                Component {
                    id: iconComponent
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: root.workspaceButtonWidth * 0.50
                        color: wsNum.contentColor
                        text: {
                            switch (wsNum.wsId) {
                                case 1:  return "code"
                                case 2:  return "public"
                                case 3:  return "music_note"
                                case 4:  return "edit_square"
                                case 5:  return "image"
                                case 6:  return "forum"
                                case 7:  return "browser_updated"
                                case 8:  return "finance_mode"
                                case 9:  return "monitor"
                                case 10: return "analytics"
                                default: return "circle"
                            }
                        }
                    }
                }
            }
        }
        FadeLoader {
            shown: wsNum.showingNumbers
            anchors.centerIn: parent
            StyledText {
                anchors.centerIn: parent
                font {
                    pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                    family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                }
                color: wsNum.contentColor
                text: Config.options?.bar.workspaces.numberMap[wsNum.wsId - 1] || wsNum.wsId
            }
        }
    }

    component TrailingIndicator: Item {
        id: trailingIndicator
        anchors.fill: parent
        required property int index
        property alias indicatorRectangle: indicatorRect
        property alias color: indicatorRect.color

        property var indexPair: AnimatedTabIndexPair {
            id: idxPair
            index: trailingIndicator.index
        }

        StyledRectangle {
            id: indicatorRect

            anchors {
                verticalCenter: root.vertical ? undefined : parent.verticalCenter
                horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            }

            property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceMargin
            property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceSize
            property real indicatorThickness: root.activeWorkspaceSize

            contentLayer: StyledRectangle.ContentLayer.Group
            radius: indicatorThickness / 2
            color: Appearance.colors.colPrimary

            x: root.vertical ? null : indicatorPosition
            y: root.vertical ? indicatorPosition : null
            implicitWidth: root.vertical ? indicatorThickness : indicatorLength
            implicitHeight: root.vertical ? indicatorLength : indicatorThickness
        }
    }
}