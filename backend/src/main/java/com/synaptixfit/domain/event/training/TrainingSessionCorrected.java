package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Se han corregido el RPE o la duración de una sesión ya terminada: Indicadores actualiza su carga
 * física. No es una nueva finalización: el calendario y los retos no cambian (por eso no se reutiliza
 * {@link TrainingSessionCompletionChanged}, que haría marcar otro bloque del día de rutina).
 *
 * @param date día local en que se terminó la sesión
 */
public record TrainingSessionCorrected(UUID userId, UUID sessionId, LocalDate date, int rpe, int durationMinutes,
                                       Instant occurredAt) implements DomainEvent {
}
