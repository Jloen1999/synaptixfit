package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Se ha superado el máximo de tareas por reto. */
public class TooManyMilestonesException extends BusinessRuleException {

    public TooManyMilestonesException(int max) {
        super("CHALLENGE_TOO_MANY_MILESTONES", "a challenge can have at most " + max + " milestones");
    }
}
