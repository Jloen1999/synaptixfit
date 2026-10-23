package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ConflictException;

/** La sesión de test ya está completada o abandonada. */
public class TestSessionNotInProgressException extends ConflictException {

    public TestSessionNotInProgressException(Object sessionId) {
        super("QUIZ_SESSION_NOT_IN_PROGRESS", "Test session " + sessionId + " is not in progress");
    }
}
