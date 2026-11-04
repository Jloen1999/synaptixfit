package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.RoutineTemplate;
import java.util.List;

/** Lista las plantillas de rutina listas para usar, en el idioma de la app. */
public interface ListRoutineTemplatesUseCase {

    List<RoutineTemplate> list(String language);
}
