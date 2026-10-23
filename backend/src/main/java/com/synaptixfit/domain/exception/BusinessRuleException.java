package com.synaptixfit.domain.exception;

/** Categoría de error: La operación incumple una regla de negocio. */
public abstract class BusinessRuleException extends DomainException {

    protected BusinessRuleException(String code, String message) {
        super(code, message);
    }
}
