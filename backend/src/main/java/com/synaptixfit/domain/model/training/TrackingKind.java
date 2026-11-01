package com.synaptixfit.domain.model.training;

/**
 * Qué se apunta en cada serie de un ejercicio (ADR 0027): repeticiones (con o sin peso), segundos de aguante
 * (plancha) o un bloque de tiempo y distancia (correr). Lo decide el dominio ({@link ExerciseRef#trackingKind()}
 * y {@link PlannedExercise#trackingKind()}); el cliente solo lo traduce a columnas.
 */
public enum TrackingKind {
    REPETITIONS,
    HOLD,
    CARDIO
}
