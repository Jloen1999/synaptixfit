package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Días de rutina saltados (a mano o al completar uno posterior). El Planificador retira sus bloques
 * pendientes: esos días ya no se van a entrenar.
 */
public record RoutineDaysSkipped(UUID userId, UUID routineId, List<UUID> dayIds, Instant occurredAt)
        implements DomainEvent {

    public RoutineDaysSkipped {
        dayIds = List.copyOf(dayIds);
    }
}
