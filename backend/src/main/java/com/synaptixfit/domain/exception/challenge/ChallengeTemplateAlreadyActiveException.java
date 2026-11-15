package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ConflictException;

/**
 * Ya hay un reto de esa plantilla sin terminar (ni completado ni vencido): dos iguales a la vez se contarían con lo
 * mismo y darían el XP dos veces (ADR 0043).
 */
public class ChallengeTemplateAlreadyActiveException extends ConflictException {

    public ChallengeTemplateAlreadyActiveException(String templateCode) {
        super("CHALLENGE_TEMPLATE_ALREADY_ACTIVE", "a challenge from template " + templateCode + " is already running");
    }
}
