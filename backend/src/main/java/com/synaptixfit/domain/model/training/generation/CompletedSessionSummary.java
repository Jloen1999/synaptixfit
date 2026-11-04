package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.SessionSet;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Sesión completada con sus series de trabajo y el ejercicio de cada una (para el historial del
 * generador). Las series de calentamiento se descartan aquí: no cuentan para el progreso (ADR 0031).
 */
public record CompletedSessionSummary(UUID sessionId, Instant completedAt, Integer rpe, int durationMinutes,
                                      List<PerformedSet> sets) {

    public CompletedSessionSummary {
        sets = (sets == null ? List.<PerformedSet>of() : sets).stream()
                .filter(p -> p != null && p.set() != null && !p.set().warmup())
                .toList();
    }

    /** Serie realizada de un ejercicio concreto. */
    public record PerformedSet(UUID exerciseId, String exerciseName, SessionSet set) {
    }
}
