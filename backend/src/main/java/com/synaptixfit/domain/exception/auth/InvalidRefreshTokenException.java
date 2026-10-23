package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.AuthenticationException;

/** El token de refresco no es válido, ha caducado o fue revocado. */
public class InvalidRefreshTokenException extends AuthenticationException {

    public InvalidRefreshTokenException() {
        super("AUTH_INVALID_REFRESH_TOKEN", "Refresh token is invalid, expired or revoked");
    }
}
