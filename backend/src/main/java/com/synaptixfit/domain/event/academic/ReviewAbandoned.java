package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Un material se ha quitado del repaso (estado «abandonado»; su historial se conserva). El planificador
 * borra sus bloques de repaso pendientes para que no queden huérfanos en el calendario.
 */
public record ReviewAbandoned(UUID userId, UUID studyMaterialId, Instant occurredAt) implements DomainEvent {
}
