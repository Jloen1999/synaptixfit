package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** Se quiso sumar un ejercicio a una sesión de rutina: solo la sesión libre lleva su propia lista (ADR 0067). */
public class SessionNotFreeException extends ConflictException {

    public SessionNotFreeException() {
        super("SESSION_NOT_FREE", "Only a free session can add exercises on the go");
    }
}
