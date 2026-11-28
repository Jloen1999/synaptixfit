package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** «Guardar como rutina» sin ninguna serie hecha con su ejercicio, o desde una sesión de rutina (ADR 0067). */
public class SessionNothingToSaveException extends BusinessRuleException {

    public SessionNothingToSaveException() {
        super("SESSION_NOTHING_TO_SAVE", "The free session has no exercise done to save as a routine");
    }
}
