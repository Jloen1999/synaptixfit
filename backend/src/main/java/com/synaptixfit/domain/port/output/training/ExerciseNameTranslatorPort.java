package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.ExerciseNameTranslations;

/**
 * Propone el nombre técnico de un ejercicio en los demás idiomas de la app a partir del español (IA).
 * Lanza AiUnavailableException o AiQuotaExceededException.
 */
public interface ExerciseNameTranslatorPort {

    ExerciseNameTranslations suggest(String spanishName);
}
