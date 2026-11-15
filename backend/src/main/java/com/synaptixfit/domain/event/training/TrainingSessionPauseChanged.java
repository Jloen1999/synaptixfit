package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Una sesión en curso se ha puesto en pausa o se ha reanudado (ADR 0030). «Entrenamos juntos» lo usa para pausar o
 * reanudar a todo el grupo a la vez (ADR 0047). Solo se publica si el estado cambia.
 *
 * @param at cuándo empezó la pausa o cuándo se reanudó (la hora del toque en el móvil, ya acotada)
 */
public record TrainingSessionPauseChanged(UUID userId, UUID sessionId, boolean paused, Instant at,
                                          Instant occurredAt) implements DomainEvent {
}
