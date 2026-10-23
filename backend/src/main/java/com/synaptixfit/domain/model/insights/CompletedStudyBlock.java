package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.model.planner.ActivityType;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Actividad académica completada: un bloque de {@code horarios_academicos} del planificador o una
 * práctica sin bloque (Pomodoro, test, repaso SM-2) expresada con el mismo vocabulario de tipos.
 *
 * @param perceivedDifficulty dificultad percibida 1-5 de la asignatura (null sin asignatura)
 * @param storedCalories      kcal ya calculadas por el planificador (null si no las guardó)
 */
public record CompletedStudyBlock(UUID id, String activityType, Instant start, Instant end,
                                  Integer perceivedDifficulty, Double storedCalories) {

    /**
     * Minutos que se imputan a un repaso SM-2: el registro solo guarda el instante, y valorar unas
     * tarjetas de un material suele llevar unos minutos (no la media hora de un bloque de repaso).
     */
    public static final int REVIEW_MINUTES = 5;
    /** Tope de un test: un test que se deja abierto horas no es estudio continuo. */
    public static final int MAX_TEST_MINUTES = 60;

    /** Fase Pomodoro completada que termina en {@code end}; cuenta como estudio. */
    public static CompletedStudyBlock focus(UUID id, Instant end, int minutes, Integer perceivedDifficulty) {
        return new CompletedStudyBlock(id, ActivityType.STUDY.code(), end.minus(Duration.ofMinutes(Math.max(1, minutes))),
                end, perceivedDifficulty, null);
    }

    /** Test de práctica terminado; cuenta como repaso con una duración real de 1 a {@value #MAX_TEST_MINUTES} min. */
    public static CompletedStudyBlock test(UUID id, Instant startedAt, Instant completedAt, Integer perceivedDifficulty) {
        Instant earliest = completedAt.minus(Duration.ofMinutes(MAX_TEST_MINUTES));
        Instant latest = completedAt.minus(Duration.ofMinutes(1));
        Instant start = startedAt == null || startedAt.isBefore(earliest) ? earliest
                : startedAt.isAfter(latest) ? latest : startedAt;
        return new CompletedStudyBlock(id, ActivityType.REVIEW.code(), start, completedAt, perceivedDifficulty, null);
    }

    /** Repaso SM-2 hecho en {@code at}; cuenta como repaso de {@value #REVIEW_MINUTES} min. */
    public static CompletedStudyBlock review(UUID id, Instant at, Integer perceivedDifficulty) {
        return new CompletedStudyBlock(id, ActivityType.REVIEW.code(), at.minus(Duration.ofMinutes(REVIEW_MINUTES)), at,
                perceivedDifficulty, null);
    }

    /** Coste cognitivo según la definición única del planificador ({@link ActivityType#isCognitive()}). */
    public static boolean isCognitive(String activityType) {
        return ActivityType.isCognitiveCode(activityType);
    }

    public long durationSeconds() {
        return Math.max(0, Duration.between(start, end).getSeconds());
    }

    public double durationMinutes() {
        return durationSeconds() / 60.0;
    }
}
