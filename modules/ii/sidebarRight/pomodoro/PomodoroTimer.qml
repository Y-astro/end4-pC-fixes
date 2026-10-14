import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.bottomMargin: 8
        spacing: 0

        ClockPicker {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 248
            Layout.preferredHeight: 248
            durationSeconds: TimerService.focusTime
            secondsLeft: TimerService.pomodoroSecondsLeft
            running: TimerService.pomodoroRunning
            onDurationEdited: seconds => TimerService.setTimerDuration(seconds)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            RippleButton {
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.pomodoroRunning ? Translation.tr("Pause") : (TimerService.pomodoroSecondsLeft === TimerService.focusTime || TimerService.pomodoroSecondsLeft === 0) ? Translation.tr("Start") : Translation.tr("Resume")
                    color: TimerService.pomodoroRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                }
                implicitHeight: 35
                implicitWidth: 90
                font.pixelSize: Appearance.font.pixelSize.larger
                onClicked: TimerService.togglePomodoro()
                colBackground: TimerService.pomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                colBackgroundHover: TimerService.pomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
            }

            RippleButton {
                implicitHeight: 35
                implicitWidth: 90
                onClicked: TimerService.resetPomodoro()
                enabled: TimerService.pomodoroRunning || TimerService.pomodoroSecondsLeft !== TimerService.focusTime
                font.pixelSize: Appearance.font.pixelSize.larger
                colBackground: Appearance.colors.colErrorContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Reset")
                    color: Appearance.colors.colOnErrorContainer
                }
            }
        }
    }
}