package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La serie no existe en la sesión. */
public class SessionSetNotFoundException extends ResourceNotFoundException {

    public SessionSetNotFoundException(Object id) {
        super("SESSION_SET_NOT_FOUND", "Session set", id);
    }
}
