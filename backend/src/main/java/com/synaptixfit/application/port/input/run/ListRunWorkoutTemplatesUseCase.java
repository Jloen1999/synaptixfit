package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.RunWorkoutTemplates;
import java.util.List;

/** Plantillas de entreno de carrera listas para usar. */
public interface ListRunWorkoutTemplatesUseCase {

    List<RunWorkoutTemplates.Template> listTemplates();
}
