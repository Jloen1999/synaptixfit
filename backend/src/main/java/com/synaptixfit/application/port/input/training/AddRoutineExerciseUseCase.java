package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Añade un ejercicio del catálogo al final de un día. */
public interface AddRoutineExerciseUseCase {

    Routine addExercise(UUID userId, UUID routineId, UUID dayId, UUID exerciseId, ExerciseParameters parameters);
}
