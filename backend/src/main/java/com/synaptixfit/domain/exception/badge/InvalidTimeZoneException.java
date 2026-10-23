package com.synaptixfit.domain.exception.badge;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La zona horaria indicada no es un identificador IANA válido. */
public class InvalidTimeZoneException extends InvalidInputException {

    public InvalidTimeZoneException(String zone) {
        super("STREAK_INVALID_ZONE", "invalid time zone: " + zone);
    }
}
