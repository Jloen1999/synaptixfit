package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.BusinessRuleException;
import com.synaptixfit.domain.model.together.FriendStreak;

/** Una de las dos personas ya tiene {@value FriendStreak#MAX_PER_PERSON} rachas con amigos (propuestas o activas). */
public class FriendStreakLimitReachedException extends BusinessRuleException {

    public FriendStreakLimitReachedException() {
        super("FRIEND_STREAK_LIMIT_REACHED", "Friend streak limit reached");
    }
}
