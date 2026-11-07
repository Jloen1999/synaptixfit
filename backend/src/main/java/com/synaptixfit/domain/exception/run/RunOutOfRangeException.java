package com.synaptixfit.domain.exception.run;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La carrera aún no ha terminado o es de hace más de 30 días (ADR 0037). */
public class RunOutOfRangeException extends BusinessRuleException {

    public RunOutOfRangeException() {
        super("RUN_OUT_OF_RANGE", "A run must have ended and be from the last 30 days");
    }
}
