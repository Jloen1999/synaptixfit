package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La sesión que se quiere repetir no tiene series con su ejercicio (p. ej. una sesión libre antigua; ADR 0067). */
public class SessionNothingToRepeatException extends BusinessRuleException {

    public SessionNothingToRepeatException() {
        super("SESSION_NOTHING_TO_REPEAT", "The session has no sets with an exercise to repeat");
    }
}
