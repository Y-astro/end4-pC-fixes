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
    readonly property real pomodoroProgress: pomodoroLapDuration > 0
        ? Math.max(0, Math.min(1, 1 - pomodoroSecondsLeft / pomodoroLapDuration)) : 0

    property bool stopwatchRunning: Persistent.states.timer.stopwatch.running
    property int stopwatchTime: 0
    property int stopwatchStart: Persistent.states.timer.stopwatch.start
    property var stopwatchLaps: Persistent.states.timer.stopwatch.laps

    // Countdown
    property bool countdownRunning: Persistent.states.timer.countdown.running
    property int countdownDuration: Persistent.states.timer.countdown.duration // seconds, total
    property int countdownStart: Persistent.states.timer.countdown.start
    property int countdownSecondsLeft: countdownDuration

    readonly property var countdowns: Persistent.states.timer.countdowns
    // Shared display clock for every countdown consumer. The list stores an
    // absolute end date, so views bind to this tick instead of each owning a
    // one-second Timer solely to refresh their remaining-time labels.
    property int countdownTick: 0
    // Monotonic suffix for timer ids: two timers created in the same
    // millisecond would otherwise share one id and be cancelled together.
    property int countdownSerial: 0

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

    function skipPomodoroPhase() {
        resetPomodoro();
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

    // Named multi-countdowns
    function countdownRemainingSeconds(countdown) {
        if (countdown?.paused)
            return Math.max(0, Math.ceil(Number(countdown?.remaining ?? 0) / 1000));
        return Math.max(0, Math.ceil((Number(countdown?.endsAt ?? 0) - Date.now()) / 1000));
    }

    function formatCountdownDuration(seconds) {
        const safe = Math.max(0, Math.floor(Number(seconds) || 0));
        const hours = Math.floor(safe / 3600);
        const minutes = Math.floor((safe % 3600) / 60);
        const secs = safe % 60;
        const padded = `${String(minutes).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
        return hours > 0 ? `${String(hours)}:${padded}` : padded;
    }

    function defaultCountdownLabel(seconds) {
        const safe = Math.max(1, Math.floor(Number(seconds) || 0));
        if (safe >= 60 && safe % 60 === 0)
            return Translation.tr("%1 minute timer").arg(String(safe / 60));
        return Translation.tr("%1 timer").arg(root.formatCountdownDuration(safe));
    }

    function findCountdown(countdownId) {
        const id = String(countdownId ?? "");
        return Array.from(Persistent.states.timer.countdowns ?? [])
            .find(countdown => String(countdown?.id ?? "") === id) ?? null;
    }

    // Timers are stored as a plain list, so every mutation rebuilds it: the
    // JsonAdapter only notifies on a new reference, never on an in-place edit.
    function updateCountdown(countdownId, changes) {
        const id = String(countdownId ?? "");
        let changed = false;
        const next = Array.from(Persistent.states.timer.countdowns ?? []).map(countdown => {
            if (String(countdown?.id ?? "") !== id)
                return countdown;
            changed = true;
            return Object.assign({}, countdown, changes);
        });
        if (changed)
            Persistent.states.timer.countdowns = next;
        return changed;
    }

    function addCountdownSeconds(seconds, label = "") {
        const durationSeconds = Math.max(1, Math.round(Number(seconds) || 0));
        const next = Array.from(Persistent.states.timer.countdowns ?? []);
        root.countdownSerial++;
        const countdown = {
            id: "countdown-" + Date.now().toString(36) + "-" + root.countdownSerial.toString(36),
            label: String(label ?? "").trim() || root.defaultCountdownLabel(durationSeconds),
            endsAt: Date.now() + durationSeconds * 1000,
            durationSeconds: durationSeconds,
            paused: false,
            remaining: 0,
            notified: false
        };
        next.unshift(countdown);
        Persistent.states.timer.countdowns = next;
        return countdown;
    }

    function addCountdown(minutes, label = "") {
        const durationMinutes = Math.max(1, Number(minutes) || 1);
        return root.addCountdownSeconds(durationMinutes * 60, String(label ?? "").trim()
            || Translation.tr("%1 minute timer").arg(String(durationMinutes)));
    }

    function pauseCountdown(countdownId) {
        const countdown = root.findCountdown(countdownId);
        if (!countdown || countdown.paused || countdown.notified)
            return;
        root.updateCountdown(countdownId, {
            paused: true,
            remaining: Math.max(0, Number(countdown.endsAt ?? 0) - Date.now())
        });
    }

    function resumeCountdown(countdownId) {
        const countdown = root.findCountdown(countdownId);
        if (!countdown || !countdown.paused || countdown.notified)
            return;
        root.updateCountdown(countdownId, {
            paused: false,
            endsAt: Date.now() + Math.max(0, Number(countdown.remaining ?? 0)),
            remaining: 0
        });
    }

    function toggleNamedCountdown(countdownId) {
        const countdown = root.findCountdown(countdownId);
        if (!countdown)
            return;
        if (countdown.paused)
            root.resumeCountdown(countdownId);
        else
            root.pauseCountdown(countdownId);
    }

    function restartCountdown(countdownId) {
        const countdown = root.findCountdown(countdownId);
        if (!countdown)
            return;
        const durationSeconds = Math.max(1, Math.round(Number(countdown.durationSeconds ?? 0) || 60));
        root.updateCountdown(countdownId, {
            endsAt: Date.now() + durationSeconds * 1000,
            paused: false,
            remaining: 0,
            notified: false
        });
    }

    /** Android's "+1:00": adds time to a running or paused timer, or rings a finished one again. */
    function extendCountdown(countdownId, seconds = 60) {
        const countdown = root.findCountdown(countdownId);
        if (!countdown)
            return;
        const extra = Math.max(1, Math.round(Number(seconds) || 60));
        if (countdown.notified) {
            root.updateCountdown(countdownId, {
                endsAt: Date.now() + extra * 1000,
                durationSeconds: extra,
                paused: false,
                remaining: 0,
                notified: false
            });
            return;
        }
        root.updateCountdown(countdownId, countdown.paused
            ? { remaining: Number(countdown.remaining ?? 0) + extra * 1000, durationSeconds: Number(countdown.durationSeconds ?? 0) + extra }
            : { endsAt: Number(countdown.endsAt ?? Date.now()) + extra * 1000, durationSeconds: Number(countdown.durationSeconds ?? 0) + extra });
    }

    function renameCountdown(countdownId, label) {
        const countdown = root.findCountdown(countdownId);
        if (!countdown)
            return;
        const text = String(label ?? "").trim();
        root.updateCountdown(countdownId, { label: text.length > 0 ? text : root.defaultCountdownLabel(countdown.durationSeconds) });
    }

    /** Fraction of the timer already elapsed, 0..1. */
    function countdownProgress(countdown) {
        const total = Math.max(1, Number(countdown?.durationSeconds ?? 1));
        return Math.max(0, Math.min(1, 1 - root.countdownRemainingSeconds(countdown) / total));
    }

    function removeCountdown(countdownId) {
        const next = Array.from(Persistent.states.timer.countdowns ?? [])
            .filter(countdown => String(countdown?.id ?? "") !== String(countdownId ?? ""));
        Persistent.states.timer.countdowns = next;
    }

    function clearFinishedCountdowns() {
        const next = Array.from(Persistent.states.timer.countdowns ?? []).filter(countdown => !countdown?.notified);
        Persistent.states.timer.countdowns = next;
    }

    // The sidebar's duration picker persists its dials here, so a keybind can
    // start the drafted timer without the tab being loaded.
    function draftCountdownSeconds() {
        const draft = Persistent.states.timer.countdownDraft;
        return Math.max(0, (Number(draft?.hours ?? 0) * 3600)
            + (Number(draft?.minutes ?? 0) * 60)
            + Number(draft?.seconds ?? 0));
    }

    function startDraftCountdown() {
        const seconds = root.draftCountdownSeconds();
        if (seconds <= 0)
            return null;
        return root.addCountdownSeconds(seconds);
    }

    /// A countdown reached zero (Modes' "A timer finishes" event).
    signal countdownFinished(var countdown)

    function refreshCountdowns() {
        const current = Array.from(Persistent.states.timer.countdowns ?? []);
        let changed = false;
        const finished = [];
        const next = current.map(countdown => {
            if (countdown.paused || countdown.notified || root.countdownRemainingSeconds(countdown) > 0)
                return countdown;
            changed = true;
            root.notifyTimerFinished(countdown.label ? `${countdown.label}: ${Translation.tr("Timer finished")}` : Translation.tr("Timer finished"));
            finished.push(countdown);
            return Object.assign({}, countdown, { notified: true });
        });
        if (changed) {
            Persistent.states.timer.countdowns = next;
        }
        for (const countdown of finished)
            root.countdownFinished(countdown);
    }

    Timer {
        id: multiCountdownTimer
        interval: 1000
        repeat: true
        running: (root.countdowns ?? []).some(countdown => !countdown.notified && !countdown.paused)
        onTriggered: {
            root.countdownTick++;
            root.refreshCountdowns();
        }
    }
}