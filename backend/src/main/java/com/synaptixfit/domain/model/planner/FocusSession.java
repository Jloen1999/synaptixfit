package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Ciclo de Pomodoro registrado (el temporizador vive en el cliente; aquí solo se guarda lo hecho).
 *
 * @param durationMinutes minutos de la fase (1-180)
 * @param cycles          ciclos completados que representa el registro (1-20)
 * @param blockId         bloque del calendario en el que se hizo (informativo: no lo completa)
 * @param subjectId       asignatura trabajada (la del bloque si no se indica)
 * @param xpAwarded       experiencia concedida por este registro ({@link FocusRewards})
 */
public record FocusSession(UUID id, UUID userId, FocusPhase phase, int durationMinutes, int cycles,
                           boolean completed, LocalDate date, UUID blockId, UUID subjectId, int xpAwarded,
                           Instant createdAt) {

    public FocusSession {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        phase = phase == null ? FocusPhase.FOCUS : phase;
        Guard.range(durationMinutes, "durationMinutes", 1, 180);
        Guard.range(cycles, "cycles", 1, 20);
        Guard.notNull(date, "date");
        xpAwarded = Math.max(0, xpAwarded);
    }

    /** Fase de concentración terminada (los descansos no son estudio). */
    public boolean isCompletedFocus() {
        return completed && phase == FocusPhase.FOCUS;
    }

    /** Copia con la experiencia concedida. */
    public FocusSession withXpAwarded(int xp) {
        return new FocusSession(id, userId, phase, durationMinutes, cycles, completed, date, blockId, subjectId, xp,
                createdAt);
    }

    /** Fase del ciclo Pomodoro. */
    public enum FocusPhase {
        FOCUS,
        SHORT_BREAK,
        LONG_BREAK
    }
}
