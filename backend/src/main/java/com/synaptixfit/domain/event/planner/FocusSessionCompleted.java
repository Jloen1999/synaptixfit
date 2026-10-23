package com.synaptixfit.domain.event.planner;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Se ha registrado una fase de concentración Pomodoro completada. Indicadores recalculan la carga
 * cognitiva de hoy y Gamificación evalúa insignias y racha (el día cuenta como activo).
 *
 * @param blockId   bloque del calendario en el que se hizo (informativo; puede ser null)
 * @param subjectId asignatura trabajada (puede ser null)
 * @param xpAwarded experiencia concedida por esta fase (0 si se alcanzó el tope diario)
 */
public record FocusSessionCompleted(UUID userId, UUID focusSessionId, LocalDate date, int durationMinutes,
                                    UUID blockId, UUID subjectId, int xpAwarded, Instant occurredAt)
        implements DomainEvent {
}
