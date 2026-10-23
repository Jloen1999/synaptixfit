package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La sesión no existe o no es del usuario. */
public class SessionNotFoundException extends ResourceNotFoundException {

    public SessionNotFoundException(Object id) {
        super("SESSION_NOT_FOUND", "Training session", id);
    }
}
