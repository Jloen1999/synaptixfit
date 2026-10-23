package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Quita un ejercicio planificado de su día. */
public interface RemoveRoutineExerciseUseCase {

    Routine removeExercise(UUID userId, UUID routineId, UUID plannedExerciseId);
}
