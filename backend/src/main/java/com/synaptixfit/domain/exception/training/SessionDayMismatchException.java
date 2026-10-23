package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El día indicado no pertenece a la rutina. */
public class SessionDayMismatchException extends InvalidInputException {

    public SessionDayMismatchException() {
        super("SESSION_DAY_MISMATCH", "The day does not belong to the given routine");
    }
}
