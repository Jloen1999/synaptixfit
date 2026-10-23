package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Una sesión de entrenamiento se ha completado o desmarcado: carga física y ACWR (Indicadores),
 * retos de fitness por sesiones e insignias (Gamificación) y bloque de deporte del día (Planificador).
 *
 * @param date         día local de la sesión (zona de los indicadores)
 * @param routineDayId día de rutina entrenado (null en sesiones libres)
 */
public record TrainingSessionCompletionChanged(UUID userId, UUID sessionId, LocalDate date, int rpe,
                                               int durationMinutes, UUID routineDayId, boolean completed,
                                               Instant occurredAt) implements DomainEvent {
}
