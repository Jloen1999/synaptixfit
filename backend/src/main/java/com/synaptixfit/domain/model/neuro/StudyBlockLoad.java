package com.synaptixfit.domain.model.neuro;

/**
 * Datos de un bloque para la carga cognitiva.
 *
 * @param durationMinutes duración del bloque
 * @param difficulty      multiplicador de dificultad (ver {@link CognitiveLoad#difficultyMultiplier})
 * @param restBeforeMinutes descanso previo al bloque
 */
public record StudyBlockLoad(double durationMinutes, double difficulty, double restBeforeMinutes) {
}
