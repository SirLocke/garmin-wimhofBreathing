using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;

class WimHofView extends WatchUi.View {
    private const PHASE_READY = 0;
    private const PHASE_BREATHS = 1;
    private const PHASE_RETENTION = 2;
    private const PHASE_RECOVERY = 3;
    private const PHASE_PAUSED = 4;
    private const PHASE_COMPLETE = 5;

    private const BREATHS_PER_ROUND = 30;
    private const TOTAL_ROUNDS = 3;
    private const RECOVERY_SECONDS = 15;

    private var _timer;
    private var _phase = PHASE_READY;
    private var _pausedPhase = PHASE_READY;
    private var _round = 1;
    private var _breaths = 0;
    private var _holdSeconds = 0;
    private var _recoverySeconds = RECOVERY_SECONDS;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        reset();
    }

    function reset() {
        if (_timer == null) {
            _timer = new Timer.Timer();
        } else {
            _timer.stop();
        }
        _phase = PHASE_READY;
        _pausedPhase = PHASE_READY;
        _round = 1;
        _breaths = 0;
        _holdSeconds = 0;
        _recoverySeconds = RECOVERY_SECONDS;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (_phase == PHASE_READY) {
            drawLines(dc, ["Atemrunden", "Sitz oder leg dich hin", "Select: Start", "Nie in/nahe Wasser", "Nicht beim Fahren"]);
        } else if (_phase == PHASE_BREATHS) {
            drawLines(dc, ["Runde " + _round.toString() + "/" + TOTAL_ROUNDS.toString(), "Atemzüge", _breaths.toString() + "/" + BREATHS_PER_ROUND.toString(), "Select: Atemzug"]);
        } else if (_phase == PHASE_RETENTION) {
            drawLines(dc, ["Ausatmen, halten", elapsedTime(), "Select bei Drang"]);
        } else if (_phase == PHASE_RECOVERY) {
            drawLines(dc, ["Erholungsatem", "Einatmen, halten", remainingTime(), "Entspannt bleiben"]);
        } else if (_phase == PHASE_PAUSED) {
            drawLines(dc, ["Pausiert", "Select: Weiter", "Back: Beenden", ""]);
        } else if (_phase == PHASE_COMPLETE) {
            drawLines(dc, ["Fertig", "Gute Arbeit", "Select: Nochmal", "Back: Schließen"]);
        } else {
            drawLines(dc, ["Atemrunden", "Sitz oder leg dich hin", "Select: Start", "Nie in/nahe Wasser", "Nicht beim Fahren"]);
        }
    }

    function advance() {
        if (_phase == PHASE_READY || _phase == PHASE_COMPLETE) {
            startSession();
        } else if (_phase == PHASE_BREATHS) {
            _breaths += 1;
            if (_breaths >= BREATHS_PER_ROUND) {
                _phase = PHASE_RETENTION;
                _holdSeconds = 0;
                startTimer();
            }
        } else if (_phase == PHASE_RETENTION) {
            _phase = PHASE_RECOVERY;
            _recoverySeconds = RECOVERY_SECONDS;
            stopTimer();
            startTimer();
        } else if (_phase == PHASE_RECOVERY) {
            // Keep the recovery hold timed so an accidental button press cannot skip it.
        } else if (_phase == PHASE_PAUSED) {
            _phase = _pausedPhase;
            if (_phase == PHASE_RETENTION || _phase == PHASE_RECOVERY) {
                startTimer();
            }
        }

        WatchUi.requestUpdate();
    }

    function back() {
        if (_phase == PHASE_READY || _phase == PHASE_COMPLETE) {
            return false;
        }

        if (_phase == PHASE_PAUSED) {
            stopTimer();
            return false;
        } else {
            _pausedPhase = _phase;
            _phase = PHASE_PAUSED;
            stopTimer();
        }
        WatchUi.requestUpdate();
        return true;
    }

    private function startSession() {
        _round = 1;
        _breaths = 0;
        _holdSeconds = 0;
        _recoverySeconds = RECOVERY_SECONDS;
        _phase = PHASE_BREATHS;
        stopTimer();
    }

    private function startTimer() {
        _timer.start(method(:onTick), 1000, true);
    }

    private function stopTimer() {
        _timer.stop();
    }

    function onTick() {
        if (_phase == PHASE_RETENTION) {
            _holdSeconds += 1;
        } else if (_phase == PHASE_RECOVERY) {
            _recoverySeconds -= 1;
            if (_recoverySeconds <= 0) {
                finishRecovery();
            }
        }
        WatchUi.requestUpdate();
    }

    private function finishRecovery() {
        stopTimer();
        if (_round >= TOTAL_ROUNDS) {
            _phase = PHASE_COMPLETE;
        } else {
            _round += 1;
            _breaths = 0;
            _phase = PHASE_BREATHS;
        }
    }

    private function elapsedTime() {
        return formatTime(_holdSeconds);
    }

    private function remainingTime() {
        return formatTime(_recoverySeconds);
    }

    private function formatTime(seconds) {
        var minutes = ((seconds - (seconds % 60)) / 60).toString();
        var remainder = (seconds % 60).toString();
        if ((seconds % 60) < 10) {
            remainder = "0" + remainder;
        }
        return minutes + ":" + remainder;
    }

    private function drawLines(dc, lines) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var lineCount = lines.size();

        for (var i = 0; i < lines.size(); i += 1) {
            if (lines[i] != "") {
                var font = i == 0 ? Graphics.FONT_SMALL : Graphics.FONT_TINY;
                var y = lineCount == 1 ? height / 2 : height * (0.20 + (0.55 * i / (lineCount - 1)));
                dc.drawText(width / 2, y, font, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}
