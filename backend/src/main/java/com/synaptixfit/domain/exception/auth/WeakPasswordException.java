package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La contraseña no cumple la política mínima. */
public class WeakPasswordException extends InvalidInputException {

    public WeakPasswordException() {
        super("AUTH_WEAK_PASSWORD", "Password must have at least 8 characters, one letter and one digit");
    }
}
