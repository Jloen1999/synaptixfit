package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.RoutineTemplate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Catálogo de plantillas de rutina (solo lectura), con los textos en el idioma pedido o en español. */
public interface RoutineTemplateRepositoryPort {

    List<RoutineTemplate> findAll(String language);

    Optional<RoutineTemplate> findById(UUID templateId, String language);
}
