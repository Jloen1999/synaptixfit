package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ConflictException;
import java.util.UUID;

/** El reto ya está completado. */
public class ChallengeAlreadyCompletedException extends ConflictException {

    public ChallengeAlreadyCompletedException(UUID id) {
        super("CHALLENGE_ALREADY_COMPLETED", "challenge " + id + " is already completed");
    }
}
