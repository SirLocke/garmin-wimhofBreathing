using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;

class WimHofView extends WatchUi.View {
    private const BREATHS_PER_ROUND = 30;
    private const TOTAL_ROUNDS = 3;
    private const RECOVERY_SECONDS = 15;

    private var _timer;
    private var _phase = "ready";
    private var _pausedPhase = "ready";
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
        _phase = "ready";
        _pausedPhase = "ready";
        _round = 1;
        _breaths = 0;
        _holdSeconds = 0;
        _recoverySeconds = RECOVERY_SECONDS;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (_phase == "ready") {
            drawLines(dc, ["Atemrunden", "Sitz oder leg dich hin", "Select: Start", "Nie in/nahe Wasser", "Nicht beim Fahren"]);
        } else if (_phase == "breaths") {
            drawLines(dc, ["Runde " + _round.toString() + "/" + TOTAL_ROUNDS.toString(), "Atemzüge", _breaths.toString() + "/" + BREATHS_PER_ROUND.toString(), "Select pro Atemzug"]);
        } else if (_phase == "retention") {
            drawLines(dc, ["Runde " + _round.toString() + "/" + TOTAL_ROUNDS.toString(), "Ausatmen, halten", elapsedTime(), "Select bei Atemdrang"]);
        } else if (_phase == "recovery") {
            drawLines(dc, ["Erholungsatem", "Einatmen, halten", remainingTime(), "Entspannt bleiben"]);
        } else if (_phase == "paused") {
            drawLines(dc, ["Pausiert", "Select: Weiter", "Back: Beenden", ""]);
        } else if (_phase == "complete") {
            drawLines(dc, ["Fertig", "Gute Arbeit", "Select: Nochmal", "Back: Schließen"]);
        } else {
            drawLines(dc, ["Atemrunden", "Sitz oder leg dich hin", "Select: Start", "Nie in/nahe Wasser", "Nicht beim Fahren"]);
        }
    }

    function advance() {
        if (_phase == "ready" || _phase == "complete") {
            startSession();
        } else if (_phase == "breaths") {
            _breaths += 1;
            if (_breaths >= BREATHS_PER_ROUND) {
                _phase = "retention";
                _holdSeconds = 0;
                startTimer();
            }
        } else if (_phase == "retention") {
            _phase = "recovery";
            _recoverySeconds = RECOVERY_SECONDS;
            stopTimer();
            startTimer();
        } else if (_phase == "recovery") {
            // Keep the recovery hold timed so an accidental button press cannot skip it.
        } else if (_phase == "paused") {
            _phase = _pausedPhase;
            if (_phase == "retention" || _phase == "recovery") {
                startTimer();
            }
        } else {
            startSession();
        }

        WatchUi.requestUpdate();
    }

    function back() {
        if (_phase == "ready" || _phase == "complete") {
            return false;
        }

        if (_phase == "paused") {
            stopTimer();
            return false;
        } else {
            _pausedPhase = _phase;
            _phase = "paused";
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
        _phase = "breaths";
        stopTimer();
    }

    private function startTimer() {
        _timer.start(method(:onTick), 1000, true);
    }

    private function stopTimer() {
        _timer.stop();
    }

    private function onTick() {
        if (_phase == "retention") {
            _holdSeconds += 1;
        } else if (_phase == "recovery") {
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
            _phase = "complete";
        } else {
            _round += 1;
            _breaths = 0;
            _phase = "breaths";
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
                var y = lineCount == 1 ? height / 2 : height * (0.18 + (0.64 * i / (lineCount - 1)));
                dc.drawText(width / 2, y, font, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}
