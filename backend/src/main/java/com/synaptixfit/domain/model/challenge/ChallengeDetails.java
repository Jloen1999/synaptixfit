package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.UUID;

/**
 * Datos editables de un reto. {@code type} nulo se deduce de la asignatura (con asignatura,
 * académico; sin ella, fitness) y {@code goal} nulo toma el título, como hacía la app antigua.
 *
 * @param sessionTarget sesiones de entrenamiento que completan un reto de fitness sin tareas (null:
 *                      el reto no avanza solo con los entrenamientos; ver ADR 0009)
 */
public record ChallengeDetails(String title, ChallengeType type, String goal, Visibility visibility,
                               Difficulty difficulty, Instant startAt, Instant endAt, UUID subjectId,
                               ChallengeLink link, Integer sessionTarget) {

    /** Reto sin objetivo de sesiones. */
    public ChallengeDetails(String title, ChallengeType type, String goal, Visibility visibility,
                            Difficulty difficulty, Instant startAt, Instant endAt, UUID subjectId, ChallengeLink link) {
        this(title, type, goal, visibility, difficulty, startAt, endAt, subjectId, link, null);
    }
}
