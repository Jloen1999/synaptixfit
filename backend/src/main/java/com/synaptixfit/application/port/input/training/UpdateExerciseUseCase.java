package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import java.util.UUID;

/** Edición de un ejercicio del catálogo (administración). */
public interface UpdateExerciseUseCase {

    Exercise update(UUID exerciseId, ExerciseDraft draft);
}
