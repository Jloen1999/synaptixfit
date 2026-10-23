package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La fecha de fin debe ser posterior a la de inicio. */
public class InvalidChallengeDatesException extends InvalidInputException {

    public InvalidChallengeDatesException() {
        super("CHALLENGE_INVALID_DATES", "endAt must be after startAt");
    }
}
