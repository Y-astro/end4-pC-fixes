pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Timer and stopwatch manager. Legacy Pomodoro names are retained for existing callers.
 */
Singleton {
    id: root

    property int focusTime: Config.options.time.pomodoro.focus
    property int breakTime: Config.options.time.pomodoro.breakTime
    property int longBreakTime: Config.options.time.pomodoro.longBreak
    property int cyclesBeforeLongBreak: Config.options.time.pomodoro.cyclesBeforeLongBreak

    property bool pomodoroRunning: Persistent.states.timer.pomodoro.running
    readonly property bool pomodoroBreak: false
    readonly property bool pomodoroLongBreak: false
    readonly property int pomodoroLapDuration: focusTime
    property int pomodoroSecondsLeft: pomodoroLapDuration // Reasonable init value, to be changed
    readonly property int pomodoroCycle: 0

    property bool stopwatchRunning: Persistent.states.timer.stopwatch.running
    property int stopwatchTime: 0
    property int stopwatchStart: Persistent.states.timer.stopwatch.start
    property var stopwatchLaps: Persistent.states.timer.stopwatch.laps

    // Countdown
    property bool countdownRunning: Persistent.states.timer.countdown.running
    property int countdownDuration: Persistent.states.timer.countdown.duration // seconds, total
    property int countdownStart: Persistent.states.timer.countdown.start
    property int countdownSecondsLeft: countdownDuration

    // General
    Component.onCompleted: {
        // Discard an old automatic break when upgrading to the one-shot timer.
        if (Persistent.states.timer.pomodoro.isBreak)
            resetPomodoro();
        Persistent.states.timer.pomodoro.isBreak = false;
        Persistent.states.timer.pomodoro.cycle = 0;
        if (!stopwatchRunning)
            stopwatchReset();
        if (!countdownRunning)
            countdownSecondsLeft = countdownDuration;
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000);
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10);
    }

    function formatSeconds(totalSeconds) {
        const s = Math.max(0, Math.round(totalSeconds));
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return `${m}:${sec.toString().padStart(2, "0")}`;
    }

    // One quiet, short ding for both timer completion paths. Keep playback
    // independent of the legacy alarm toggle so completion is audible by default.
    function notifyTimerFinished(message) {
        Quickshell.execDetached(["notify-send", "Timer", message, "-a", "Shell",
            "--urgency=normal", "--hint=boolean:suppress-sound:true"]);
        Quickshell.execDetached(["pw-play", "--volume=0.35",
            Qt.resolvedUrl("../assets/sounds/timer-ding.wav").toString().replace("file://", "")]);
    }

    // One-shot timer. Keep the API names compatible with existing shell widgets.
    function refreshPomodoro() {
        if (!Persistent.states.timer.pomodoro.running) return;
        pomodoroSecondsLeft = Math.max(0, focusTime -
            (getCurrentTimeInSeconds() - Persistent.states.timer.pomodoro.start));
        if (pomodoroSecondsLeft === 0) {
            Persistent.states.timer.pomodoro.running = false;
            notifyTimerFinished(Translation.tr("Timer finished"));
        }
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: root.pomodoroRunning
        repeat: true
        onTriggered: root.refreshPomodoro()
    }

    function setTimerDuration(seconds) {
        if (pomodoroRunning) return;
        Config.options.time.pomodoro.focus = Math.max(0, Math.min(86399, Math.round(seconds)));
        pomodoroSecondsLeft = focusTime;
    }

    function togglePomodoro() {
        if (pomodoroRunning) {
            refreshPomodoro();
            Persistent.states.timer.pomodoro.running = false;
            return;
        }
        if (focusTime <= 0) return;
        if (pomodoroSecondsLeft <= 0) pomodoroSecondsLeft = focusTime;
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds() + pomodoroSecondsLeft - focusTime;
        Persistent.states.timer.pomodoro.running = true;
    }

    function resetPomodoro() {
        Persistent.states.timer.pomodoro.running = false;
        Persistent.states.timer.pomodoro.isBreak = false;
        Persistent.states.timer.pomodoro.cycle = 0;
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds();
        pomodoroSecondsLeft = focusTime;
    }

    // Stopwatch
    function refreshStopwatch() {  // Stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStart;
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: root.stopwatchRunning
        repeat: true
        onTriggered: refreshStopwatch()
    }

    function toggleStopwatch() {
        if (root.stopwatchRunning)
            stopwatchPause();
        else
            stopwatchResume();
    }

    function stopwatchPause() {
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchResume() {
        if (stopwatchTime === 0) Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = true;
        Persistent.states.timer.stopwatch.start = getCurrentTimeIn10ms() - stopwatchTime;
    }

    function stopwatchReset() {
        stopwatchTime = 0;
        Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchRecordLap() {
        Persistent.states.timer.stopwatch.laps.push(stopwatchTime);
    }

    // Countdown
    function refreshCountdown() {
        if (!Persistent.states.timer.countdown.running) return;

        const elapsed = getCurrentTimeInSeconds() - Persistent.states.timer.countdown.start;
        let left = Persistent.states.timer.countdown.duration - elapsed;

        if (left <= 0) {
            left = 0;
            Persistent.states.timer.countdown.running = false;
            Persistent.states.timer.countdown.duration = 0;
            notifyTimerFinished(Translation.tr("Countdown finished"));
        }

        countdownSecondsLeft = left;
    }

    Timer {
        id: countdownTimer
        interval: 200
        running: root.countdownRunning
        repeat: true
        onTriggered: refreshCountdown()
    }

    // Adds minutes to the countdown. Works whether paused or running.
    function addCountdownMinutes(minutes) {
        const addSeconds = minutes * 60;
        if (root.countdownRunning) {
            Persistent.states.timer.countdown.duration += addSeconds;
        } else {
            Persistent.states.timer.countdown.duration = (Persistent.states.timer.countdown.duration ?? 0) + addSeconds;
            countdownSecondsLeft = Persistent.states.timer.countdown.duration;
        }
    }

    function toggleCountdown() {
        if (countdownDuration <= 0) return;
        Persistent.states.timer.countdown.running = !countdownRunning;
        if (Persistent.states.timer.countdown.running) {
            Persistent.states.timer.countdown.start = getCurrentTimeInSeconds() - (countdownDuration - countdownSecondsLeft);
        }
    }

    function resetCountdown() {
        Persistent.states.timer.countdown.running = false;
        Persistent.states.timer.countdown.duration = 0;
        countdownSecondsLeft = 0;
    }
}