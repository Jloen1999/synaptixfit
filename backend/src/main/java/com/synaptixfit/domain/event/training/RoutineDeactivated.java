package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Una rutina deja de estar en curso (pausada, también al activar otra; borrada; o ciclo terminado).
 * El Planificador borra sus bloques futuros pendientes para que el calendario no proponga entrenar
 * una rutina que ya no se sigue.
 */
public record RoutineDeactivated(UUID userId, UUID routineId, Reason reason, Instant occurredAt)
        implements DomainEvent {

    /** Por qué deja de estar en curso. */
    public enum Reason {
        PAUSED,
        DELETED,
        COMPLETED
    }
}
