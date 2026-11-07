package com.synaptixfit.domain.exception.user;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Fecha de nacimiento futura o con una edad fuera de lo razonable (ver {@code BirthDate}). */
public class InvalidBirthDateException extends InvalidInputException {

    public InvalidBirthDateException(String message) {
        super("INVALID_BIRTH_DATE", message);
    }
}
