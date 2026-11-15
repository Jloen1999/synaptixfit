package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.ConflictException;

/**
 * La acción no vale en el estado actual: responder a una invitación ya respondida, unirse a un reto terminado o
 * empezar un «Entrenamos juntos» de otro día.
 */
public class TogetherInvalidStateException extends ConflictException {

    public TogetherInvalidStateException(String detail) {
        super("TOGETHER_INVALID_STATE", detail);
    }
}
