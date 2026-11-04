package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** El día del ciclo es del futuro o de hace más de un año. */
public class CycleDayOutOfRangeException extends BusinessRuleException {

    public CycleDayOutOfRangeException() {
        super("CYCLE_DAY_OUT_OF_RANGE", "A cycle day must be from today or the last year");
    }
}
