package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.RoutineTemplateDetail;
import java.util.UUID;

/** Detalle de una plantilla de rutina ofrecida (días y ejercicios), en el idioma de la app. */
public interface GetRoutineTemplateUseCase {

    RoutineTemplateDetail getTemplate(UUID templateId, String language);
}
