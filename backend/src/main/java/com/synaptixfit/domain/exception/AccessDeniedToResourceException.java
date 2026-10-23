package com.synaptixfit.domain.exception;

/** Operación reservada a administradores u otro rol. */
public class AccessDeniedToResourceException extends ForbiddenOperationException {

    public AccessDeniedToResourceException(String message) {
        super("FORBIDDEN", message);
    }
}
