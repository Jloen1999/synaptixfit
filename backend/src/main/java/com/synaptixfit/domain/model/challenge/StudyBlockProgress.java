package com.synaptixfit.domain.model.challenge;

import java.util.OptionalDouble;

/** Bloques de estudio del calendario asignados a una tarea: totales y completados (de Planificador). */
public record StudyBlockProgress(int total, int completed) {

    /** Tarea sin bloques. */
    public static final StudyBlockProgress NONE = new StudyBlockProgress(0, 0);

    /** Porcentaje completado; vacío si la tarea no tiene bloques. */
    public OptionalDouble percent() {
        return total <= 0 ? OptionalDouble.empty() : OptionalDouble.of(Math.min(100.0, completed * 100.0 / total));
    }
}
