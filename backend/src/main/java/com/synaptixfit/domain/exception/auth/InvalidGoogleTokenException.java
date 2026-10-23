package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.AuthenticationException;

/** El token de Google no se pudo verificar. */
public class InvalidGoogleTokenException extends AuthenticationException {

    public InvalidGoogleTokenException() {
        super("AUTH_INVALID_GOOGLE_TOKEN", "Google ID token could not be verified");
    }
}
