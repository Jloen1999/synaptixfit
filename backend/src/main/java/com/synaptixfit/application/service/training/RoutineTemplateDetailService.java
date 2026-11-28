package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetRoutineTemplateUseCase;
import com.synaptixfit.domain.exception.training.RoutineTemplateNotFoundException;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.RoutineTemplateDetail;
import com.synaptixfit.domain.model.training.RoutineTemplateDetail.ExerciseInfo;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Implementa {@link GetRoutineTemplateUseCase}: lee la plantilla con {@link RoutineTemplateRepositoryPort} y el nombre
 * y la foto de sus ejercicios con {@link ExerciseRepositoryPort} (una sola lectura para todos). Solo se enseñan las
 * plantillas que se ofrecen (activas y con días), las mismas que se pueden usar: una retirada es un 404.
 */
public class RoutineTemplateDetailService implements GetRoutineTemplateUseCase {

    private final RoutineTemplateRepositoryPort templates;
    private final ExerciseRepositoryPort exercises;

    public RoutineTemplateDetailService(RoutineTemplateRepositoryPort templates, ExerciseRepositoryPort exercises) {
        this.templates = templates;
        this.exercises = exercises;
    }

    @Override
    public RoutineTemplateDetail getTemplate(UUID templateId, String language) {
        RoutineTemplate template = templates.findById(templateId, language)
                .filter(t -> t.active() && !t.days().isEmpty())
                .orElseThrow(() -> new RoutineTemplateNotFoundException(templateId));
        Map<UUID, ExerciseInfo> info = new HashMap<>();
        exercises.findByIds(template.exerciseIds()).forEach((id, e) -> info.put(id, infoOf(e)));
        return new RoutineTemplateDetail(template, info);
    }

    private static ExerciseInfo infoOf(Exercise e) {
        return new ExerciseInfo(e.name(), ExerciseRef.stillImage(e.previewUrl(), e.gifUrl()));
    }
}
