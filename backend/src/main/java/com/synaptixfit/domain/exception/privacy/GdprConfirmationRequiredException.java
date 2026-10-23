package com.synaptixfit.domain.exception.privacy;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Darse de baja exige la contraseña (si la cuenta la tiene) o una confirmación explícita. */
public class GdprConfirmationRequiredException extends InvalidInputException {

    public GdprConfirmationRequiredException(String message) {
        super("GDPR_CONFIRMATION_REQUIRED", message);
    }
}
