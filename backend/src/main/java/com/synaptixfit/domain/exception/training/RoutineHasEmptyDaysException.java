package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Una rutina solo se puede completar si tiene días y ninguno está vacío. */
public class RoutineHasEmptyDaysException extends BusinessRuleException {

    public RoutineHasEmptyDaysException() {
        super("ROUTINE_HAS_EMPTY_DAYS", "A routine can only be completed when it has days and none of them is empty");
    }
}
