using Toybox.Lang;
using Toybox.Test;

class BreathingFlowTests {
    (:test)
    static function startsWithBreathingPhase(logger as Test.Logger) as Lang.Boolean {
        var flow = new BreathingFlow();
        if (flow.getPhase() != flow.PHASE_READY || flow.getRound() != 1) {
            logger.error("New flow should be ready at round one");
            return false;
        }

        flow.advance();
        if (flow.getPhase() != flow.PHASE_BREATHS) {
            logger.error("Starting should enter the breathing phase");
            return false;
        }
        return true;
    }

    (:test)
    static function retentionCanExceedOneMinute(logger as Test.Logger) as Lang.Boolean {
        var flow = new BreathingFlow();
        flow.start();
        flow.advance();

        flow.tickElapsed(65);

        var formatted = flow.formatTime(65);
        if (flow.getPhase() != flow.PHASE_RETENTION || flow.getHoldSeconds() != 65 || !formatted.equals("1:05")) {
            logger.error("Unexpected retention value: phase=" + flow.getPhase().toString() + ", seconds=" + flow.getHoldSeconds().toString() + ", formatted=" + formatted);
            return false;
        }
        return true;
    }

    (:test)
    static function recoveryAdvancesRoundsAndCompletes(logger as Test.Logger) as Lang.Boolean {
        var flow = new BreathingFlow();
        flow.start();

        for (var round = 1; round <= flow.getTotalRounds(); round += 1) {
            flow.advance();
            flow.advance();
            flow.tickElapsed(flow.RECOVERY_SECONDS);

            if (round < flow.getTotalRounds()) {
                if (flow.getPhase() != flow.PHASE_BREATHS || flow.getRound() != round + 1) {
                    logger.error("Recovery should start the next round");
                    return false;
                }
            }
        }

        if (flow.getPhase() != flow.PHASE_COMPLETE) {
            logger.error("The final recovery should complete the session");
            return false;
        }

        flow.advance();
        if (flow.getPhase() != flow.PHASE_BREATHS || flow.getRound() != 1) {
            logger.error("Starting again should reset to round one");
            return false;
        }
        return true;
    }

    (:test)
    static function delayedRecoveryCallbackStillTransitions(logger as Test.Logger) as Lang.Boolean {
        var flow = new BreathingFlow();
        flow.start();
        flow.advance();
        flow.advance();
        flow.tickElapsed(flow.RECOVERY_SECONDS + 3);

        if (flow.getPhase() != flow.PHASE_BREATHS || flow.getRound() != 2 || flow.getRecoverySeconds() != 0) {
            logger.error("A delayed recovery update should transition when the deadline has elapsed");
            return false;
        }
        return true;
    }

    (:test)
    static function pausePreservesTheOpenHold(logger as Test.Logger) as Lang.Boolean {
        var flow = new BreathingFlow();
        flow.start();
        flow.advance();
        flow.tick();
        flow.pause();
        flow.tick();

        if (flow.getPhase() != flow.PHASE_PAUSED || flow.getHoldSeconds() != 1) {
            logger.error("Paused time should not advance the hold");
            return false;
        }

        flow.advance();
        flow.tick();
        if (flow.getPhase() != flow.PHASE_RETENTION || flow.getHoldSeconds() != 2) {
            logger.error("Resuming should continue the same hold");
            return false;
        }
        return true;
    }

    (:test)
    static function tracksMaxAndTotalHoldAcrossRounds(logger as Test.Logger) as Lang.Boolean {
        var flow = new BreathingFlow();
        flow.start();

        // Round 1: 45s hold
        flow.advance();
        flow.tickElapsed(45);
        flow.advance();
        flow.tickElapsed(flow.RECOVERY_SECONDS);

        // Round 2: 90s hold
        flow.advance();
        flow.tickElapsed(90);
        flow.advance();
        flow.tickElapsed(flow.RECOVERY_SECONDS);

        // Round 3: 75s hold
        flow.advance();
        flow.tickElapsed(75);
        flow.advance();

        if (flow.getMaxHoldSeconds() != 90 || flow.getTotalHoldSeconds() != 210 || flow.getCompletedHolds() != 3) {
            logger.error("Unexpected hold summary: max=" + flow.getMaxHoldSeconds().toString() + ", total=" + flow.getTotalHoldSeconds().toString() + ", count=" + flow.getCompletedHolds().toString());
            return false;
        }
        return true;
    }
}
