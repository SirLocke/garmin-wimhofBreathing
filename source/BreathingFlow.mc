using Toybox.Lang;

class BreathingFlow {
    const PHASE_READY = 0;
    const PHASE_BREATHS = 1;
    const PHASE_RETENTION = 2;
    const PHASE_RECOVERY = 3;
    const PHASE_PAUSED = 4;
    const PHASE_COMPLETE = 5;

    const TOTAL_ROUNDS = 3;
    const RECOVERY_SECONDS = 15;

    private var _phase = PHASE_READY;
    private var _pausedPhase = PHASE_READY;
    private var _round = 1;
    private var _holdSeconds = 0;
    private var _maxHoldSeconds = 0;
    private var _totalHoldSeconds = 0;
    private var _completedHolds = 0;
    private var _recoverySeconds = RECOVERY_SECONDS;

    function initialize() {
        reset();
    }

    function reset() as Void {
        _phase = PHASE_READY;
        _pausedPhase = PHASE_READY;
        _round = 1;
        _holdSeconds = 0;
        _maxHoldSeconds = 0;
        _totalHoldSeconds = 0;
        _completedHolds = 0;
        _recoverySeconds = RECOVERY_SECONDS;
    }

    function getPhase() as Lang.Number {
        return _phase;
    }

    function getRound() as Lang.Number {
        return _round;
    }

    function getHoldSeconds() as Lang.Number {
        return _holdSeconds;
    }

    function getMaxHoldSeconds() as Lang.Number {
        return _maxHoldSeconds;
    }

    function getTotalHoldSeconds() as Lang.Number {
        return _totalHoldSeconds;
    }

    function getCompletedHolds() as Lang.Number {
        return _completedHolds;
    }

    function getRecoverySeconds() as Lang.Number {
        return _recoverySeconds;
    }

    function getTotalRounds() as Lang.Number {
        return TOTAL_ROUNDS;
    }

    function start() as Void {
        reset();
        _phase = PHASE_BREATHS;
    }

    function advance() as Void {
        if (_phase == PHASE_READY || _phase == PHASE_COMPLETE) {
            start();
        } else if (_phase == PHASE_BREATHS) {
            _phase = PHASE_RETENTION;
            _holdSeconds = 0;
        } else if (_phase == PHASE_RETENTION) {
            if (_holdSeconds > _maxHoldSeconds) {
                _maxHoldSeconds = _holdSeconds;
            }
            _totalHoldSeconds += _holdSeconds;
            _completedHolds += 1;
            _phase = PHASE_RECOVERY;
            _recoverySeconds = RECOVERY_SECONDS;
        } else if (_phase == PHASE_PAUSED) {
            _phase = _pausedPhase;
        }
    }

    function pause() as Void {
        if (_phase != PHASE_PAUSED && _phase != PHASE_READY && _phase != PHASE_COMPLETE) {
            _pausedPhase = _phase;
            _phase = PHASE_PAUSED;
        }
    }

    function tick() as Void {
        tickElapsed(1);
    }

    function tickElapsed(elapsedSeconds as Lang.Number) as Void {
        if (elapsedSeconds <= 0) {
            return;
        }

        if (_phase == PHASE_RETENTION) {
            _holdSeconds += elapsedSeconds;
        } else if (_phase == PHASE_RECOVERY) {
            _recoverySeconds -= elapsedSeconds;
            if (_recoverySeconds <= 0) {
                _recoverySeconds = 0;
                if (_round >= TOTAL_ROUNDS) {
                    _phase = PHASE_COMPLETE;
                } else {
                    _round += 1;
                    _phase = PHASE_BREATHS;
                }
            }
        }
    }

    function isTimedPhase() as Lang.Boolean {
        return _phase == PHASE_RETENTION || _phase == PHASE_RECOVERY;
    }

    function formatTime(seconds as Lang.Number) as Lang.String {
        var minutes = ((seconds - (seconds % 60)) / 60).toString();
        var remainder = (seconds % 60).toString();
        if ((seconds % 60) < 10) {
            remainder = "0" + remainder;
        }
        return minutes + ":" + remainder;
    }
}
