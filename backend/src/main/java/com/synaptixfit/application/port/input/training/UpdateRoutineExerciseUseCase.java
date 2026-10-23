package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Cambia los parámetros de un ejercicio planificado. */
public interface UpdateRoutineExerciseUseCase {

    Routine updateExercise(UUID userId, UUID routineId, UUID plannedExerciseId, ExerciseParameters parameters);
}
