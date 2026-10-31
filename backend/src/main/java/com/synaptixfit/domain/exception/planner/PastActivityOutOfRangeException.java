package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La actividad que se quiere apuntar aún no ha terminado o es de hace más de 7 días. */
public class PastActivityOutOfRangeException extends BusinessRuleException {

    public PastActivityOutOfRangeException() {
        super("PLANNER_PAST_ACTIVITY_OUT_OF_RANGE", "A past activity must have ended and be from the last 7 days");
    }
}
