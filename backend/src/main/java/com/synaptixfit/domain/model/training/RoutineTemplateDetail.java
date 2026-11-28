package com.synaptixfit.domain.model.training;

import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Detalle de una plantilla de rutina para decidir antes de usarla: la plantilla y, por id, el nombre y la foto fija de
 * cada ejercicio que incluye (los que ya no están en el catálogo no salen en {@code exercises}).
 */
public record RoutineTemplateDetail(RoutineTemplate template, Map<UUID, ExerciseInfo> exercises) {

    /** Nombre y foto fija de un ejercicio (la vista previa o, si no hay, la animación; nula sin ninguna). */
    public record ExerciseInfo(String name, String imageUrl) {
    }

    public RoutineTemplateDetail {
        Objects.requireNonNull(template, "template");
        exercises = Map.copyOf(exercises);
    }
}
