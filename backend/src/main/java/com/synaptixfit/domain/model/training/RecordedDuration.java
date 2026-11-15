package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;

/**
 * Duración real de un ejercicio planificado en una sesión terminada (segundos que contó la sesión en vivo) y cuándo
 * se apuntó. {@link PlannedExercise} guarda las últimas {@value PlannedExercise#RECENT_DURATIONS} y
 * {@link SessionDurationEstimate} aprende de ellas (ADR 0048).
 */
public record RecordedDuration(int seconds, Instant recordedAt) {

    public RecordedDuration {
        Guard.range(seconds, "seconds", 1, Integer.MAX_VALUE);
        Guard.notNull(recordedAt, "recordedAt");
    }
}
