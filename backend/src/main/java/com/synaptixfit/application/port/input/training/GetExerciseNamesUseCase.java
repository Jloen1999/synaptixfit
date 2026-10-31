package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import java.util.UUID;

/** Nombres de un ejercicio en los demás idiomas, para editarlos (administración). */
public interface GetExerciseNamesUseCase {

    ExerciseNameTranslations names(UUID exerciseId);
}
