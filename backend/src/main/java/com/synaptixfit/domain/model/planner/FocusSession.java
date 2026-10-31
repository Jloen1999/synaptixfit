package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Objects;
import java.util.Set;
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

    /** Días hacia atrás que se aceptan: lo justo para guardar una fase que terminó pasada la medianoche. */
    public static final int MAX_DAYS_BACK = 1;

    /**
     * Día con el que se registra una fase: hoy si no se indica o es futuro, y como mucho ayer hacia atrás.
     * Sin este límite se podían registrar fases de cualquier día pasado e inventar una racha entera.
     */
    public static LocalDate recordedDay(LocalDate requested, LocalDate today) {
        if (requested == null || requested.isAfter(today)) {
            return today;
        }
        if (requested.isBefore(today.minusDays(MAX_DAYS_BACK))) {
            throw new FieldValidationException("date", "OUT_OF_RANGE",
                    "date must be today or at most " + MAX_DAYS_BACK + " day(s) ago");
        }
        return requested;
    }

    /** Fase de concentración terminada (los descansos no son estudio). */
    public boolean isCompletedFocus() {
        return completed && phase == FocusPhase.FOCUS;
    }

    /** Cuenta para la racha: una fase de concentración terminada de al menos {@link FocusRewards#MIN_CYCLE_MINUTES}. */
    public boolean countsForStreak() {
        return isCompletedFocus() && durationMinutes >= FocusRewards.MIN_CYCLE_MINUTES;
    }

    /**
     * Minutos de concentración terminados que no están ya contados por un bloque completado (los de un
     * bloque hecho ya suman con su duración): así el objetivo semanal cuenta también el estudio con
     * Pomodoro sin bloque, igual que los minutos de estudio de Inicio.
     */
    public static long focusMinutesOutside(Collection<FocusSession> sessions, Set<UUID> completedBlockIds) {
        return sessions.stream()
                .filter(s -> s.isCompletedFocus() && (s.blockId() == null || !completedBlockIds.contains(s.blockId())))
                .mapToLong(FocusSession::durationMinutes)
                .sum();
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
