package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** La sesión ya está finalizada. */
public class SessionAlreadyCompletedException extends ConflictException {

    public SessionAlreadyCompletedException() {
        super("SESSION_ALREADY_COMPLETED", "The session is already completed");
    }
}
