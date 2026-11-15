package com.synaptixfit.domain.exception.badge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Ya se usaron los días de pausa de racha de los últimos 90 días (ADR 0042). */
public class StreakPauseLimitReachedException extends BusinessRuleException {

    public StreakPauseLimitReachedException() {
        super("STREAK_PAUSE_LIMIT_REACHED", "No streak pause days left in the current window");
    }
}
