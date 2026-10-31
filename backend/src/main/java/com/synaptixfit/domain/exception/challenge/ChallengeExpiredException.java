package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** El reto ya venció: no admite progreso ni completarse fuera de plazo (ni su XP). */
public class ChallengeExpiredException extends BusinessRuleException {

    public ChallengeExpiredException(UUID id) {
        super("CHALLENGE_EXPIRED", "challenge " + id + " has already ended");
    }
}
