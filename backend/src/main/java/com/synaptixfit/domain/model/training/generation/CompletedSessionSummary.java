package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.SessionSet;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Sesión completada con sus series y el ejercicio de cada una (para el historial del generador). */
public record CompletedSessionSummary(UUID sessionId, Instant completedAt, Integer rpe, int durationMinutes,
                                      List<PerformedSet> sets) {

    public CompletedSessionSummary {
        sets = List.copyOf(sets == null ? List.of() : sets);
    }

    /** Serie realizada de un ejercicio concreto. */
    public record PerformedSet(UUID exerciseId, String exerciseName, SessionSet set) {
    }
}
