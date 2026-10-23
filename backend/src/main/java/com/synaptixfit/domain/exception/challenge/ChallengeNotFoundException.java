package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El reto no existe o no es visible para el usuario. */
public class ChallengeNotFoundException extends ResourceNotFoundException {

    public ChallengeNotFoundException(UUID id) {
        super("CHALLENGE_NOT_FOUND", "Challenge", id);
    }
}
