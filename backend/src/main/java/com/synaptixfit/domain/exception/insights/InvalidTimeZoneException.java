package com.synaptixfit.domain.exception.insights;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La zona horaria indicada no es un identificador IANA válido (p. ej. {@code Europe/Madrid}). */
public class InvalidTimeZoneException extends InvalidInputException {

    public InvalidTimeZoneException(String zone) {
        super("INSIGHTS_INVALID_TIME_ZONE", "Invalid time zone: " + zone);
    }
}
