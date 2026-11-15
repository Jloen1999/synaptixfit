package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Plantillas de reto productivo para el modo de uso de la persona (ADR 0043), en el idioma de la app, con el código
 * de las que ya tiene en marcha.
 */
public interface ListChallengeTemplatesUseCase {

    /** Plantillas disponibles y los códigos de las que ya tienen un reto sin terminar. */
    record Gallery(List<ChallengeTemplate> templates, Set<String> running) {
    }

    Gallery listTemplates(UUID userId, String language);
}
