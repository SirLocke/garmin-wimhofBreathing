using Toybox.Graphics;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.FitContributor;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class WimHofView extends WatchUi.View {
    private const RECORDING_NONE = 0;
    private const RECORDING_ACTIVE = 1;
    private const RECORDING_SAVED = 2;
    private const RECORDING_FAILED = 3;
    private const RECORDING_INCOMPLETE = 4;

    private const COLOR_ICE = 0x55D9E8;
    private const COLOR_AMBER = 0xFFB454;
    private const COLOR_MUTED = 0x7B8794;
    private const COLOR_RING = 0x303841;
    private const DISPLAY_EDGE_INSET = 8;

    private var _flow;
    private var _timer;
    private var _recordingSession;
    private var _lapHoldField;
    private var _maxHoldField;
    private var _totalHoldField;
    private var _completedRoundsField;
    private var _recordingStatus = RECORDING_NONE;
    private var _recordingIncomplete = false;
    private var _topButtonHint;
    private var _bottomButtonHint;
    private var _lastTickAt;
    private var _tickRemainderMs = 0;

    function initialize() {
        View.initialize();
        _flow = new BreathingFlow();
        _timer = new Timer.Timer();
    }

    function onAppStop() {
        stopTimer(false);
        finishRecording();
    }

    function onLayout(dc) {
        _topButtonHint = WatchUi.loadResource(Rez.Drawables.RightTopHint);
        _bottomButtonHint = WatchUi.loadResource(Rez.Drawables.RightBottomHint);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var phase = _flow.getPhase();
        if (phase == _flow.PHASE_READY) {
            drawReady(dc);
        } else if (phase == _flow.PHASE_BREATHS) {
            drawBreaths(dc);
        } else if (phase == _flow.PHASE_RETENTION) {
            drawRetention(dc);
        } else if (phase == _flow.PHASE_RECOVERY) {
            drawRecovery(dc);
        } else if (phase == _flow.PHASE_PAUSED) {
            drawPaused(dc);
        } else {
            drawComplete(dc);
        }

        drawButtonHints(dc, phase);
    }

    function advance() {
        updateTimedPhase();
        var oldPhase = _flow.getPhase();
        if (oldPhase == _flow.PHASE_READY || oldPhase == _flow.PHASE_COMPLETE) {
            startSession();
        } else {
            _flow.advance();
            var newPhase = _flow.getPhase();
            if (oldPhase == _flow.PHASE_BREATHS && newPhase == _flow.PHASE_RETENTION) {
                startTimer(false);
            } else if (oldPhase == _flow.PHASE_RETENTION && newPhase == _flow.PHASE_RECOVERY) {
                recordRoundHold(_flow.getHoldSeconds());
                stopTimer(false);
                startTimer(false);
            } else if (oldPhase == _flow.PHASE_PAUSED) {
                resumeRecording();
                if (_flow.isTimedPhase()) {
                    startTimer(true);
                }
            }
        }

        WatchUi.requestUpdate();
    }

    function back() {
        updateTimedPhase();
        var phase = _flow.getPhase();
        if (phase == _flow.PHASE_READY || phase == _flow.PHASE_COMPLETE) {
            return false;
        }

        if (phase == _flow.PHASE_PAUSED) {
            stopTimer(false);
            finishRecording();
            return false;
        }

        _flow.pause();
        stopTimer(true);
        pauseRecording();
        WatchUi.requestUpdate();
        return true;
    }

    function onTick() {
        updateTimedPhase();
        WatchUi.requestUpdate();
    }

    private function drawReady(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawCentered(dc, cx, cy * 0.12, Graphics.FONT_SMALL, "ATEMRUNDEN", Graphics.COLOR_WHITE);

        var outerRadius = scaledDimension(dc, 42);
        var middleRadius = (outerRadius * 29) / 42;
        var innerRadius = (outerRadius * 15) / 42;
        var centerRadius = (outerRadius * 4) / 42;
        var motifY = cy * 0.33;
        dc.setPenWidth(2);
        dc.setColor(COLOR_RING, Graphics.COLOR_BLACK);
        dc.drawCircle(cx, motifY, outerRadius);
        dc.setColor(COLOR_ICE, Graphics.COLOR_BLACK);
        dc.drawCircle(cx, motifY, middleRadius);
        dc.drawCircle(cx, motifY, innerRadius);
        dc.fillCircle(cx, motifY, centerRadius);

        drawCentered(dc, cx, cy * 0.53, Graphics.FONT_SMALL, "3 Runden", Graphics.COLOR_WHITE);
        drawCentered(dc, cx, cy * 0.62, Graphics.FONT_TINY, "je ca. 30 Atemzüge", COLOR_MUTED);
        drawCentered(dc, cx, cy * 0.71, Graphics.FONT_TINY, "Sitzend und trocken", Graphics.COLOR_WHITE);
        drawCentered(dc, cx, cy * 0.78, Graphics.FONT_TINY, "Nie im Wasser / Verkehr", COLOR_MUTED);
    }

    private function drawBreaths(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawHeader(dc, "ATMEN");
        drawRoundProgress(dc, cx, cy * 0.26);

        dc.setPenWidth(2);
        dc.setColor(COLOR_RING, Graphics.COLOR_BLACK);
        dc.drawCircle(cx, cy * 0.45, scaledDimension(dc, 43));
        dc.setColor(COLOR_ICE, Graphics.COLOR_BLACK);
        dc.drawCircle(cx, cy * 0.45, scaledDimension(dc, 39));
        drawCentered(dc, cx, cy * 0.45, Graphics.FONT_NUMBER_MEDIUM, "30", Graphics.COLOR_WHITE);
        drawCentered(dc, cx - 32, cy * 0.67, Graphics.FONT_XTINY, "Tief in den Bauch", COLOR_MUTED);
        drawCentered(dc, cx - 32, cy * 0.74, Graphics.FONT_XTINY, "Locker ausatmen", COLOR_MUTED);
    }

    private function drawRetention(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawHeader(dc, "HALTEN");
        drawRoundProgress(dc, cx, cy * 0.26);
        drawTimerRing(dc, cx, cy * 0.44, COLOR_ICE, 1.0);
        drawCentered(dc, cx, cy * 0.44, Graphics.FONT_MEDIUM, _flow.formatTime(_flow.getHoldSeconds()), Graphics.COLOR_WHITE);
        drawCentered(dc, cx - 18, cy * 0.61, Graphics.FONT_TINY, "ohne Druck halten", COLOR_MUTED);
    }

    private function drawRecovery(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawHeader(dc, "ERHOLUNG");
        drawRoundProgress(dc, cx, cy * 0.26);

        var elapsed = _flow.RECOVERY_SECONDS - _flow.getRecoverySeconds();
        var progress = elapsed.toFloat() / _flow.RECOVERY_SECONDS.toFloat();
        drawTimerRing(dc, cx, cy * 0.44, COLOR_AMBER, progress);
        drawCentered(dc, cx, cy * 0.44, Graphics.FONT_MEDIUM, _flow.formatTime(_flow.getRecoverySeconds()), Graphics.COLOR_WHITE);
        drawCentered(dc, cx - 18, cy * 0.61, Graphics.FONT_TINY, "einatmen · halten", COLOR_MUTED);
        drawCentered(dc, cx - 18, cy * 0.79, Graphics.FONT_TINY, "wartet 15 Sekunden", Graphics.COLOR_WHITE);
    }

    private function drawPaused(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawHeader(dc, "PAUSIERT");
        dc.setPenWidth(5);
        dc.setColor(COLOR_ICE, Graphics.COLOR_BLACK);
        dc.drawLine(cx - 11, cy * 0.35, cx - 11, cy * 0.49);
        dc.drawLine(cx + 11, cy * 0.35, cx + 11, cy * 0.49);
        drawCentered(dc, cx - 18, cy * 0.59, Graphics.FONT_SMALL, "Ruhig bleiben", Graphics.COLOR_WHITE);
    }

    private function drawComplete(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawHeader(dc, "GESCHAFFT");
        drawRoundProgress(dc, cx, cy * 0.26);
        dc.setPenWidth(3);
        dc.setColor(COLOR_ICE, Graphics.COLOR_BLACK);
        dc.drawCircle(cx, cy * 0.46, scaledDimension(dc, 39));
        dc.drawLine(cx - 14, cy * 0.46, cx - 3, cy * 0.51);
        dc.drawLine(cx - 3, cy * 0.51, cx + 18, cy * 0.40);
        drawCentered(dc, cx - 40, cy * 0.65, Graphics.FONT_SMALL, recordingMessage(), Graphics.COLOR_WHITE);
    }

    private function drawHeader(dc, title as Lang.String) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight();
        drawCentered(dc, cx - 18, cy * 0.12, Graphics.FONT_SMALL, title, Graphics.COLOR_WHITE);
        drawCentered(dc, cx - 32, cy * 0.22, Graphics.FONT_XTINY, "RUNDE " + _flow.getRound().toString(), COLOR_MUTED);
    }

    private function drawRoundProgress(dc, cx as Lang.Number, y as Lang.Number) {
        var spacing = 18;
        var startX = cx - spacing;
        for (var i = 1; i <= _flow.getTotalRounds(); i += 1) {
            var x = startX + ((i - 1) * spacing);
            if (i <= _flow.getRound()) {
                dc.setColor(COLOR_ICE, Graphics.COLOR_BLACK);
                dc.fillCircle(x, y, 4);
            } else {
                dc.setColor(COLOR_RING, Graphics.COLOR_BLACK);
                dc.drawCircle(x, y, 4);
            }
        }
    }

    private function drawTimerRing(dc, cx as Lang.Number, cy as Lang.Number, accent as Lang.Number, progress as Lang.Float) {
        var radius = scaledDimension(dc, 36);
        dc.setPenWidth(3);
        dc.setColor(COLOR_RING, Graphics.COLOR_BLACK);
        dc.drawCircle(cx, cy, radius);

        var sweep = progress * 360.0;
        if (sweep > 0.0) {
            dc.setColor(accent, Graphics.COLOR_BLACK);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90.0, 90.0 + sweep);
        }
    }

    private function drawButtonHints(dc, phase as Lang.Number) {
        var topLabel = null;
        var bottomLabel = null;

        if (phase == _flow.PHASE_READY) {
            topLabel = "START";
        } else if (phase == _flow.PHASE_BREATHS) {
            topLabel = "HALTEN";
            bottomLabel = "PAUSE";
        } else if (phase == _flow.PHASE_RETENTION) {
            topLabel = "WEITER";
            bottomLabel = "PAUSE";
        } else if (phase == _flow.PHASE_RECOVERY) {
            bottomLabel = "PAUSE";
        } else if (phase == _flow.PHASE_PAUSED) {
            topLabel = "WEITER";
            bottomLabel = "BEENDEN";
        } else {
            topLabel = "NOCHMAL";
            bottomLabel = "BACK";
        }

        var width = dc.getWidth();
        var height = dc.getHeight();
        var topLabelY = height * 0.165;
        var topIconY = height * 0.192;
        var bottomY = height * 0.662;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // Garmin removes a personality hint on products without that physical key.
        // Keep the matching text hidden too so touch or two-button products do not
        // advertise an action they cannot perform from that position.
        if (topLabel != null && hasButtonHint(_topButtonHint)) {
            dc.drawText(width - 37, topLabelY, Graphics.FONT_XTINY, topLabel, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawBitmap(width - 36, topIconY, _topButtonHint);
        }
        if (bottomLabel != null && hasButtonHint(_bottomButtonHint)) {
            dc.drawText(width - 37, bottomY, Graphics.FONT_XTINY, bottomLabel, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawBitmap(width - 36, bottomY, _bottomButtonHint);
        }
    }

    private function hasButtonHint(bitmap) as Lang.Boolean {
        if (bitmap == null) {
            return false;
        }
        return bitmap.getWidth() > 1 && bitmap.getHeight() > 1;
    }

    private function drawCentered(dc, x as Lang.Number, y as Lang.Number, font as Lang.Number, value as Lang.String, color as Lang.Number) {
        var candidates;
        if (font == Graphics.FONT_NUMBER_HOT) {
            candidates = [font, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        } else if (font == Graphics.FONT_NUMBER_MEDIUM || font == Graphics.FONT_MEDIUM) {
            candidates = [font, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        } else if (font == Graphics.FONT_SMALL) {
            candidates = [font, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        } else if (font == Graphics.FONT_TINY) {
            candidates = [font, Graphics.FONT_XTINY];
        } else {
            candidates = [font];
        }

        var fittedFont = font;
        var candidateCount = candidates.size();
        for (var i = 0; i < candidateCount; i += 1) {
            var candidate = candidates[i];
            var availableWidth = safeTextWidth(dc, x, y, candidate);
            if (dc.getTextWidthInPixels(value, candidate) <= availableWidth) {
                fittedFont = candidate;
                break;
            }
            if (i == candidateCount - 1) {
                fittedFont = candidate;
            }
        }

        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(x, y, fittedFont, value, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function safeTextWidth(dc, x as Lang.Number, y as Lang.Number, font as Lang.Number) as Lang.Number {
        return DisplayLayout.safeCircularTextWidthAt(
            dc.getWidth(),
            dc.getHeight(),
            x,
            y,
            dc.getFontHeight(font),
            DISPLAY_EDGE_INSET
        );
    }

    private function scaledDimension(dc, baseSize as Lang.Number) as Lang.Number {
        var minDimension = dc.getWidth();
        if (dc.getHeight() < minDimension) {
            minDimension = dc.getHeight();
        }
        return (minDimension * baseSize) / 260;
    }

    private function startSession() {
        if (_recordingSession != null && !finishRecording()) {
            _recordingStatus = RECORDING_FAILED;
            WatchUi.requestUpdate();
            return;
        }

        _flow.start();
        startRecording();
        stopTimer(false);
    }

    private function startTimer(preserveRemainder as Lang.Boolean) {
        if (!preserveRemainder) {
            _tickRemainderMs = 0;
        }
        _lastTickAt = System.getTimer();
        _timer.start(method(:onTick), 1000, true);
    }

    private function stopTimer(preserveRemainder as Lang.Boolean) {
        _timer.stop();
        _lastTickAt = null;
        if (!preserveRemainder) {
            _tickRemainderMs = 0;
        }
    }

    private function updateTimedPhase() {
        if (!_flow.isTimedPhase() || _lastTickAt == null) {
            return;
        }

        var now = System.getTimer();
        var elapsedMs = now - _lastTickAt;
        if (elapsedMs < 0) {
            // System.getTimer() rolls over about every 25 days. A session is
            // far shorter; a negative delta here is one timer interval crossing
            // that boundary.
            elapsedMs = 1000;
        }
        _lastTickAt = now;

        var totalMs = _tickRemainderMs + elapsedMs;
        var elapsedSeconds = (totalMs - (totalMs % 1000)) / 1000;
        _tickRemainderMs = totalMs % 1000;
        if (elapsedSeconds <= 0) {
            return;
        }

        var oldPhase = _flow.getPhase();
        _flow.tickElapsed(elapsedSeconds);
        var newPhase = _flow.getPhase();
        if (oldPhase == _flow.PHASE_RECOVERY && newPhase != _flow.PHASE_RECOVERY) {
            stopTimer(false);
            if (newPhase == _flow.PHASE_BREATHS) {
                addRoundLap();
            } else if (newPhase == _flow.PHASE_COMPLETE) {
                finishRecording();
            }
        }
    }

    private function configureFitFields() {
        _lapHoldField = null;
        _maxHoldField = null;
        _totalHoldField = null;
        _completedRoundsField = null;
        if (_recordingSession == null || !(Toybox has :FitContributor)) {
            return;
        }
        try {
            _lapHoldField = _recordingSession.createField(
                "Round hold",
                0,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "s"}
            );
            _maxHoldField = _recordingSession.createField(
                "Max hold",
                1,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "s"}
            );
            _totalHoldField = _recordingSession.createField(
                "Total hold",
                2,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "s"}
            );
            _completedRoundsField = _recordingSession.createField(
                "Completed rounds",
                3,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "rounds"}
            );
        } catch (e) {
            // Keep session active even if FitContributor fails on older firmware
        }
    }

    private function recordRoundHold(holdSec as Lang.Number) {
        try {
            if (_lapHoldField != null) {
                _lapHoldField.setData(holdSec);
            }
            if (_maxHoldField != null) {
                _maxHoldField.setData(_flow.getMaxHoldSeconds());
            }
            if (_totalHoldField != null) {
                _totalHoldField.setData(_flow.getTotalHoldSeconds());
            }
            if (_completedRoundsField != null) {
                _completedRoundsField.setData(_flow.getCompletedHolds());
            }
        } catch (e) {
        }
    }

    private function addRoundLap() {
        try {
            if (_recordingSession != null && _recordingSession.isRecording()) {
                _recordingSession.addLap();
            }
        } catch (e) {
        }
    }

    private function startRecording() {
        _recordingStatus = RECORDING_FAILED;
        _recordingIncomplete = false;

        if (!(Toybox has :ActivityRecording)) {
            return;
        }

        var subSport = Activity.SUB_SPORT_GENERIC;
        if (Activity has :SUB_SPORT_BREATHING) {
            subSport = Activity.SUB_SPORT_BREATHING;
        }

        try {
            _recordingSession = ActivityRecording.createSession({
                :name=>"Atemrunden",
                :sport=>Activity.SPORT_TRAINING,
                :subSport=>subSport
            });
            configureFitFields();
        } catch (e) {
            _recordingSession = null;
            return;
        }

        if (_recordingSession.start()) {
            _recordingStatus = RECORDING_ACTIVE;
        } else {
            _recordingIncomplete = true;
            if (_recordingSession.discard()) {
                _recordingSession = null;
                _recordingIncomplete = false;
            }
        }
    }

    private function pauseRecording() {
        if (_recordingSession != null && !RecordingStopGuard.stopIfRecording(_recordingSession)) {
            _recordingStatus = RECORDING_FAILED;
            _recordingIncomplete = true;
        }
    }

    private function resumeRecording() {
        if (_recordingSession != null && !_recordingSession.isRecording()) {
            if (_recordingSession.start()) {
                _recordingStatus = RECORDING_ACTIVE;
            } else {
                _recordingIncomplete = true;
                if (_recordingSession.save()) {
                    _recordingSession = null;
                    _recordingStatus = RECORDING_INCOMPLETE;
                } else {
                    _recordingStatus = RECORDING_FAILED;
                    if (_recordingSession.discard()) {
                        _recordingSession = null;
                        _recordingIncomplete = false;
                    }
                }
            }
        }
    }

    private function finishRecording() as Lang.Boolean {
        if (_recordingSession == null) {
            return true;
        }

        recordRoundHold(_flow.getHoldSeconds());

        if (!RecordingStopGuard.stopIfRecording(_recordingSession)) {
            _recordingStatus = RECORDING_FAILED;
            _recordingIncomplete = true;
            return false;
        }

        if (_recordingSession.save()) {
            _recordingStatus = _recordingIncomplete ? RECORDING_INCOMPLETE : RECORDING_SAVED;
            _recordingSession = null;
            return true;
        } else {
            _recordingStatus = RECORDING_FAILED;
            if (_recordingSession.discard()) {
                _recordingSession = null;
                _recordingIncomplete = false;
                return true;
            }
        }

        return false;
    }

    private function recordingMessage() as Lang.String {
        if (_recordingStatus == RECORDING_SAVED) {
            return "FIT gespeichert";
        } else if (_recordingStatus == RECORDING_FAILED) {
            return "FIT fehlgeschlagen";
        } else if (_recordingStatus == RECORDING_INCOMPLETE) {
            return "FIT unvollständig";
        }
        return "";
    }
}
