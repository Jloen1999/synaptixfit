package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La sesión de test no existe o no es del usuario. */
public class TestSessionNotFoundException extends ResourceNotFoundException {

    public TestSessionNotFoundException(Object id) {
        super("QUIZ_SESSION_NOT_FOUND", "Test session", id);
    }
}
