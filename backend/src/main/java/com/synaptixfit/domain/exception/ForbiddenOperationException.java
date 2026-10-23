package com.synaptixfit.domain.exception;

/** Categoría de error: El usuario está autenticado pero no puede realizar la operación. */
public abstract class ForbiddenOperationException extends DomainException {

    protected ForbiddenOperationException(String code, String message) {
        super(code, message);
    }
}
