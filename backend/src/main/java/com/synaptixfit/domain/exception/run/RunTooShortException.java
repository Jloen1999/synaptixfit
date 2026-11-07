package com.synaptixfit.domain.exception.run;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La carrera tiene menos de 10 minutos en movimiento: como cualquier actividad, no cuenta (ADR 0033 y 0037). */
public class RunTooShortException extends BusinessRuleException {

    public RunTooShortException() {
        super("RUN_TOO_SHORT", "A run needs at least 10 minutes moving");
    }
}
