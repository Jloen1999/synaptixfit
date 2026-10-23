package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La rutina no tiene días que distribuir en el calendario. */
public class RoutineWithoutDaysException extends BusinessRuleException {

    public RoutineWithoutDaysException() {
        super("PLANNER_ROUTINE_EMPTY", "The routine has no days to distribute");
    }
}
