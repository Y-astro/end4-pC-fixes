pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sessionScreen
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

/**
 * The session menu, inside the island.
 *
 * The same eight actions in the same four-by-two grid as the full-screen session
 * screen, drawn with the same SessionActionButton - only smaller, and on the island's
 * surface instead of over a dimmed desktop. Reusing the button is what keeps the two in
 * step: its shape, its colours, its focus behaviour and its keyboard handling are the
 * session screen's, not a copy of them.
 *
 * Sized like search: it declares what it wants and the island animates to it, so the
 * two are never chasing each other.
 */
FocusScope {
    id: root

    /** The island hands these over; see NotchContent. */
    property bool active: false
    signal closeRequested

    // ── What the island should be ────────────────────────────────────────────
    /** Declared, never measured off anything that moves. */
    readonly property real buttonSize: 84
    readonly property real gridSpacing: 6
    readonly property real padding: 14
    readonly property real headerHeight: 30

    readonly property real contentTargetWidth: 4 * root.buttonSize + 3 * root.gridSpacing + 2 * root.padding
    readonly property real contentTargetHeight: root.headerHeight + 2 * root.buttonSize
        + root.gridSpacing + 2 * root.padding

    /** The action the keyboard is on, named in the header - the icons alone are terse. */
    property string focusedAction: Translation.tr("Lock")

    function hide() {
        root.closeRequested();
    }

    function focusFirstButton() {
        sessionLock.forceActiveFocus();
    }

    /** The cascade the session screen plays, so the buttons arrive the same way. */
    function animateIn() {
        sessionLock.animateIn();
        sessionSleep.animateIn();
        sessionLogout.animateIn();
        sessionOledSaver.animateIn();
        sessionHibernate.animateIn();
        sessionShutdown.animateIn();
        sessionReboot.animateIn();
        sessionFirmwareReboot.animateIn();
        root.focusFirstButton();
    }

    function animateOut() {
        sessionLock.animateOut();
        sessionSleep.animateOut();
        sessionLogout.animateOut();
        sessionOledSaver.animateOut();
        sessionHibernate.animateOut();
        sessionShutdown.animateOut();
        sessionReboot.animateOut();
        sessionFirmwareReboot.animateOut();
    }

    onActiveChanged: {
        if (root.active) {
            SessionWarnings.refresh();
            root.animateIn();
            Qt.callLater(root.focusFirstButton);
        } else {
            root.animateOut();
        }
    }

    Component.onCompleted: {
        if (root.active) {
            Qt.callLater(root.focusFirstButton);
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.hide();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Left ||
                   event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
                   event.key === Qt.Key_Tab) {
            root.focusFirstButton();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 0

        // Title on the left, the focused action on the right: the session screen says
        // both too, and here it costs one row rather than three.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: 8

            StyledText {
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.large
                    variableAxes: Appearance.font.variableAxes.title
                }
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Session")
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                text: root.focusedAction
                elide: Text.ElideRight
                Layout.maximumWidth: root.width / 2
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 4
            columnSpacing: root.gridSpacing
            rowSpacing: root.gridSpacing

            component IslandSessionButton: RippleButton {
                id: button
                property string buttonIcon
                property string buttonText
                property bool keyboardDown: false
                property real size: root.buttonSize
                property real iconSize: Math.round(button.size * 0.375)
                property int animIndex: 0
                property bool shown: false

                onFocusChanged: {
                    if (focus)
                        root.focusedAction = buttonText;
                }
                onActiveFocusChanged: {
                    if (activeFocus)
                        root.focusedAction = buttonText;
                }

                HoverHandler {
                    id: hoverHandler
                    onHoveredChanged: {
                        if (hovered) {
                            button.forceActiveFocus();
                        }
                    }
                }

                readonly property bool isHovered: hoverHandler.hovered || button.hovered
                readonly property bool activeState: button.activeFocus || button.focus || button.isHovered || button.isPressed || button.keyboardDown

                property real animScale: button.shown ? 1.0 : 0.7
                property real animTranslateX: button.shown ? 0 : -35
                property real animOpacity: button.shown ? 1.0 : 0.0

                property real outerRadius: Math.min(button.size / 2, Appearance.rounding.large)
                property bool outerTopLeft: false
                property bool outerTopRight: false
                property bool outerBottomLeft: false
                property bool outerBottomRight: false

                property real inactiveRadius: (Appearance.rounding.scale === 0)
                    ? 0
                    : (GlobalStates.islandOwnsSession ? 6 : Appearance.rounding.windowRounding)

                readonly property real innerCornerRadius: button.activeState ? button.size / 2 : button.inactiveRadius
                readonly property real outerCornerRadius: button.activeState ? button.size / 2 : button.outerRadius

                topLeftRadius: button.outerTopLeft ? button.outerCornerRadius : button.innerCornerRadius
                topRightRadius: button.outerTopRight ? button.outerCornerRadius : button.innerCornerRadius
                bottomLeftRadius: button.outerBottomLeft ? button.outerCornerRadius : button.innerCornerRadius
                bottomRightRadius: button.outerBottomRight ? button.outerCornerRadius : button.innerCornerRadius

                component RadiusBehavior: NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
                Behavior on topLeftRadius { RadiusBehavior { } }
                Behavior on topRightRadius { RadiusBehavior { } }
                Behavior on bottomLeftRadius { RadiusBehavior { } }
                Behavior on bottomRightRadius { RadiusBehavior { } }

                colBackground: button.keyboardDown ? Appearance.colors.colSecondaryContainerActive : 
                    button.activeState ? Appearance.colors.colPrimary : 
                    Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colPrimary
                colRipple: Appearance.colors.colPrimaryActive
                property color colText: button.activeState ?
                    Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                background.implicitHeight: size
                background.implicitWidth: size

                scale: (button.down ? 0.94 : (button.activeState ? 1.04 : 1.0)) * animScale

                transform: Translate {
                    x: button.animTranslateX
                }

                opacity: animOpacity

                Behavior on animScale {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                }

                Behavior on animTranslateX {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on animOpacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    id: cascadeTimer
                    interval: animIndex * 35
                    repeat: false
                    onTriggered: {
                        button.shown = true;
                    }
                }

                function animateIn() {
                    button.shown = false;
                    cascadeTimer.restart();
                }

                function animateOut() {
                    cascadeTimer.stop();
                    button.shown = false;
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        keyboardDown = true;
                        button.clicked();
                        event.accepted = true;
                    }
                }
                Keys.onReleased: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        keyboardDown = false;
                        event.accepted = true;
                    }
                }

                contentItem: MaterialSymbol {
                    id: icon
                    anchors.fill: parent
                    color: button.colText
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: button.iconSize
                    text: buttonIcon
                    fill: button.activeState ? 1 : 0
                }

                StyledToolTip {
                    text: buttonText
                }
            }

            IslandSessionButton {
                id: sessionLock
                animIndex: 0
                outerTopLeft: true
                focus: root.active
                buttonIcon: "lock"
                buttonText: Translation.tr("Lock")
                onClicked: {
                    root.hide();
                    Session.lock();
                }
                KeyNavigation.right: sessionSleep
                KeyNavigation.left: sessionOledSaver
                KeyNavigation.down: sessionHibernate
                KeyNavigation.up: sessionHibernate
                KeyNavigation.tab: sessionSleep
                KeyNavigation.backtab: sessionFirmwareReboot
            }
            IslandSessionButton {
                id: sessionSleep
                animIndex: 1
                buttonIcon: "dark_mode"
                buttonText: Translation.tr("Sleep")
                onClicked: {
                    root.hide();
                    Session.suspend();
                }
                KeyNavigation.left: sessionLock
                KeyNavigation.right: sessionLogout
                KeyNavigation.down: sessionShutdown
                KeyNavigation.up: sessionShutdown
                KeyNavigation.tab: sessionLogout
                KeyNavigation.backtab: sessionLock
            }
            IslandSessionButton {
                id: sessionLogout
                animIndex: 2
                buttonIcon: "logout"
                buttonText: Translation.tr("Logout")
                onClicked: {
                    root.hide();
                    Session.logout();
                }
                KeyNavigation.left: sessionSleep
                KeyNavigation.right: sessionOledSaver
                KeyNavigation.down: sessionReboot
                KeyNavigation.up: sessionReboot
                KeyNavigation.tab: sessionOledSaver
                KeyNavigation.backtab: sessionSleep
            }
            IslandSessionButton {
                id: sessionOledSaver
                animIndex: 3
                outerTopRight: true
                buttonIcon: "tv_off"
                buttonText: Translation.tr("OLED Saver")
                onClicked: {
                    root.hide();
                    const name = Hyprland.focusedMonitor?.name || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
                    if (name) {
                        const monitors = GlobalStates.oledSaverMonitors;
                        GlobalStates.oledSaverMonitors = monitors.includes(name) ? monitors.filter(n => n !== name) : [...monitors, name];
                    }
                }
                KeyNavigation.left: sessionLogout
                KeyNavigation.right: sessionLock
                KeyNavigation.down: sessionFirmwareReboot
                KeyNavigation.up: sessionFirmwareReboot
                KeyNavigation.tab: sessionHibernate
                KeyNavigation.backtab: sessionLogout
            }

            IslandSessionButton {
                id: sessionHibernate
                animIndex: 4
                outerBottomLeft: true
                buttonIcon: "downloading"
                buttonText: Translation.tr("Hibernate")
                onClicked: {
                    root.hide();
                    Session.hibernate();
                }
                KeyNavigation.up: sessionLock
                KeyNavigation.down: sessionLock
                KeyNavigation.left: sessionFirmwareReboot
                KeyNavigation.right: sessionShutdown
                KeyNavigation.tab: sessionShutdown
                KeyNavigation.backtab: sessionOledSaver
            }
            IslandSessionButton {
                id: sessionShutdown
                animIndex: 5
                buttonIcon: "power_settings_new"
                buttonText: Translation.tr("Shutdown")
                onClicked: {
                    root.hide();
                    Session.poweroff();
                }
                KeyNavigation.left: sessionHibernate
                KeyNavigation.right: sessionReboot
                KeyNavigation.up: sessionSleep
                KeyNavigation.down: sessionSleep
                KeyNavigation.tab: sessionReboot
                KeyNavigation.backtab: sessionHibernate
            }
            IslandSessionButton {
                id: sessionReboot
                animIndex: 6
                buttonIcon: "restart_alt"
                buttonText: Translation.tr("Reboot")
                onClicked: {
                    root.hide();
                    Session.reboot();
                }
                KeyNavigation.left: sessionShutdown
                KeyNavigation.right: sessionFirmwareReboot
                KeyNavigation.up: sessionLogout
                KeyNavigation.down: sessionLogout
                KeyNavigation.tab: sessionFirmwareReboot
                KeyNavigation.backtab: sessionShutdown
            }
            IslandSessionButton {
                id: sessionFirmwareReboot
                animIndex: 7
                outerBottomRight: true
                buttonIcon: "settings_applications"
                buttonText: Translation.tr("Reboot to firmware settings")
                onClicked: {
                    root.hide();
                    Session.rebootToFirmware();
                }
                KeyNavigation.left: sessionReboot
                KeyNavigation.right: sessionHibernate
                KeyNavigation.up: sessionOledSaver
                KeyNavigation.down: sessionOledSaver
                KeyNavigation.tab: sessionLock
                KeyNavigation.backtab: sessionReboot
            }
        }
    }
}
