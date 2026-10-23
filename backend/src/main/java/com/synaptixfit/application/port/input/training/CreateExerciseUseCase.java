package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseDraft;

/** Alta de un ejercicio en el catálogo (administración). */
public interface CreateExerciseUseCase {

    Exercise create(ExerciseDraft draft);
}
