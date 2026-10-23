package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Una rutina debe tener entre 1 y 52 semanas. */
public class RoutineWeekLimitException extends BusinessRuleException {

    public RoutineWeekLimitException() {
        super("ROUTINE_WEEK_LIMIT", "A routine must have between 1 and 52 weeks");
    }
}
