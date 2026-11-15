package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import java.util.UUID;

/** «Empezar este reto»: crea un reto propio y privado desde una plantilla, que se cuenta solo (ADR 0043). */
public interface StartChallengeTemplateUseCase {

    Challenge startTemplate(UUID userId, UUID templateId, String language);
}
