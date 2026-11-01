package com.synaptixfit.domain.model.training;

import java.util.Objects;
import java.util.UUID;

/**
 * Cambio propuesto para un ejercicio planificado (resultado de la progresión o la degradación).
 *
 * @param before     parámetros que tenía al proponerse (nulo en sugerencias antiguas): el cliente
 *                   enseña «40 → 42,5 kg» sin calcular nada
 * @param reasonCode por qué cambia (nulo en sugerencias antiguas o si solo se ajusta al rango del
 *                   objetivo); {@code reason} es la nota técnica
 */
public record ExerciseAdjustment(UUID plannedExerciseId, UUID exerciseId, String exerciseName,
                                 ExerciseParameters parameters, String reason, ExerciseParameters before,
                                 AdjustmentReason reasonCode) {

    public ExerciseAdjustment {
        Objects.requireNonNull(plannedExerciseId, "plannedExerciseId");
        Objects.requireNonNull(parameters, "parameters");
    }

    public ExerciseAdjustment(UUID plannedExerciseId, UUID exerciseId, String exerciseName,
                              ExerciseParameters parameters, String reason) {
        this(plannedExerciseId, exerciseId, exerciseName, parameters, reason, null, null);
    }
}
