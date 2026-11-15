package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La plantilla de reto no existe o no es para el modo de uso de la persona (ADR 0043). */
public class ChallengeTemplateNotFoundException extends ResourceNotFoundException {

    public ChallengeTemplateNotFoundException(UUID id) {
        super("CHALLENGE_TEMPLATE_NOT_FOUND", "ChallengeTemplate", id);
    }
}
