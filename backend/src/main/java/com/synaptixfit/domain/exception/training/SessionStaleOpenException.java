package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/**
 * Hay una sesión de ese día abandonada (abierta hace más de 6 h): antes de empezar otra hay que
 * terminarla con lo registrado o descartarla. Así nunca se pierden series sin que la persona lo decida.
 */
public class SessionStaleOpenException extends ConflictException {

    public SessionStaleOpenException(Object sessionId) {
        super("SESSION_STALE_OPEN", "Session " + sessionId + " was left open: finish or discard it first");
    }
}
