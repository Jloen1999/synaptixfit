package com.synaptixfit.domain.port.output.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Catálogo de plantillas de reto (solo lectura, ADR 0043), con los textos en el idioma pedido o en español. */
public interface ChallengeTemplateRepositoryPort {

    List<ChallengeTemplate> findAll(String language);

    Optional<ChallengeTemplate> findById(UUID templateId, String language);
}
