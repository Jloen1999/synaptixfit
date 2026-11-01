package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Días quitados de la estructura de una rutina (al borrar un día o una semana). Se publica
 * <b>antes</b> de guardar el borrado: la base de datos pone a null el enlace de los bloques del
 * calendario ({@code ON DELETE SET NULL}) y, sin este aviso, esos bloques pasarían a ser deporte libre
 * con XP y carga propias. El Planificador borra los pendientes.
 */
public record RoutineDaysRemoved(UUID userId, UUID routineId, List<UUID> dayIds, Instant occurredAt)
        implements DomainEvent {

    public RoutineDaysRemoved {
        dayIds = List.copyOf(dayIds);
    }
}
