package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Crea una rutina propia (privada) a partir de una plantilla, con su nombre en el idioma de la app. */
public interface CreateRoutineFromTemplateUseCase {

    Routine createFromTemplate(UUID userId, UUID templateId, String language);
}
