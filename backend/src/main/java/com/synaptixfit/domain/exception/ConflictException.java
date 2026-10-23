package com.synaptixfit.domain.exception;

/** Categoría de error: La operación choca con el estado actual (duplicados, carreras de escritura…). */
public abstract class ConflictException extends DomainException {

    protected ConflictException(String code, String message) {
        super(code, message);
    }
}
