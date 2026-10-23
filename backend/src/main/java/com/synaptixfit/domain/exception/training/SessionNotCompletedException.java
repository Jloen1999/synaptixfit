package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** La sesión no está finalizada. */
public class SessionNotCompletedException extends ConflictException {

    public SessionNotCompletedException() {
        super("SESSION_NOT_COMPLETED", "The session is not completed");
    }
}
