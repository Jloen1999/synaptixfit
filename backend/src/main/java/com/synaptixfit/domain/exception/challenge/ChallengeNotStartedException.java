package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** El reto aún no ha empezado: no se puede completar ni avanzar antes de su fecha de inicio (ADR 0028). */
public class ChallengeNotStartedException extends BusinessRuleException {

    public ChallengeNotStartedException(UUID id) {
        super("CHALLENGE_NOT_STARTED", "challenge " + id + " has not started yet");
    }
}
