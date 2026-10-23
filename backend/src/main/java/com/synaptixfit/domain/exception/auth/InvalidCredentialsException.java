package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.AuthenticationException;

/** Email o contraseña incorrectos. */
public class InvalidCredentialsException extends AuthenticationException {

    public InvalidCredentialsException() {
        super("AUTH_INVALID_CREDENTIALS", "Invalid email or password");
    }
}
