package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseNameTranslations;

/** Propone con IA el nombre de un ejercicio en los demás idiomas (administración; no guarda nada). */
public interface SuggestExerciseNamesUseCase {

    ExerciseNameTranslations suggest(String spanishName);
}
