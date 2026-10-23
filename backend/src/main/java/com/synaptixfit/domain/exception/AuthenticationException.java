package com.synaptixfit.domain.exception;

/** Categoría de error: Credenciales o sesión inválidas. */
public abstract class AuthenticationException extends DomainException {

    protected AuthenticationException(String code, String message) {
        super(code, message);
    }
}
