package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** «Recordárselo» no vale ahora: ya se avisó hoy, el amigo ya hizo su parte o la racha no está activa. */
public class FriendStreakNudgeUnavailableException extends BusinessRuleException {

    public FriendStreakNudgeUnavailableException() {
        super("FRIEND_STREAK_NUDGE_UNAVAILABLE", "Nudge not available today");
    }
}
