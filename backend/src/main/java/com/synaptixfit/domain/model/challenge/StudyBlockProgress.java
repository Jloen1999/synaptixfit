package com.synaptixfit.domain.model.challenge;

/** Bloques de estudio vinculados a una tarea: totales y completados. */
public record StudyBlockProgress(int total, int completed) {

    /** Porcentaje completado; vacío si la tarea no tiene bloques. */
    public java.util.OptionalDouble percent() {
        return total <= 0 ? java.util.OptionalDouble.empty()
                : java.util.OptionalDouble.of(Math.min(100.0, completed * 100.0 / total));
    }
}
