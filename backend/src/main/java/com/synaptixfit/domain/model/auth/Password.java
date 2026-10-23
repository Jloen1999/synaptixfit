package com.synaptixfit.domain.model.auth;

import com.synaptixfit.domain.exception.auth.WeakPasswordException;

/** Contraseña en claro validada contra la política mínima. Nunca se persiste. */
public record Password(String value) {

    public static final int MIN_LENGTH = 8;

    public Password {
        if (value == null || value.length() < MIN_LENGTH || value.length() > 128
                || value.chars().noneMatch(Character::isLetter)
                || value.chars().noneMatch(Character::isDigit)) {
            throw new WeakPasswordException();
        }
    }

    @Override
    public String toString() {
        return "Password[***]";
    }
}
