package com.synaptixfit.domain.exception;

/** Invariante de un campo concreto incumplida. Se traduce como {@code VALIDATION_ERROR} con {@code fields}. */
public class FieldValidationException extends InvalidInputException {

    private final String field;
    private final String fieldCode;

    public FieldValidationException(String field, String fieldCode, String message) {
        super("VALIDATION_ERROR", message);
        this.field = field;
        this.fieldCode = fieldCode;
    }

    public String field() {
        return field;
    }

    public String fieldCode() {
        return fieldCode;
    }
}
