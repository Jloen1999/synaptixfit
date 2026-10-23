package com.synaptixfit.domain.exception;

/** Categoría de error: El recurso solicitado no existe o no pertenece al usuario. */
public abstract class NotFoundException extends DomainException {

    protected NotFoundException(String code, String message) {
        super(code, message);
    }
}
