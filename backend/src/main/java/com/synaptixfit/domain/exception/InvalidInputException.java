package com.synaptixfit.domain.exception;

/** Categoría de error: Los datos de entrada no cumplen las invariantes del modelo. */
public abstract class InvalidInputException extends DomainException {

    protected InvalidInputException(String code, String message) {
        super(code, message);
    }
}
