package com.synaptixfit.domain.model.training;

import java.util.Objects;
import java.util.UUID;

/** Cambio propuesto para un ejercicio planificado (resultado de la progresión o la degradación). */
public record ExerciseAdjustment(UUID plannedExerciseId, UUID exerciseId, String exerciseName,
                                 ExerciseParameters parameters, String reason) {

    public ExerciseAdjustment {
        Objects.requireNonNull(plannedExerciseId, "plannedExerciseId");
        Objects.requireNonNull(parameters, "parameters");
    }
}
