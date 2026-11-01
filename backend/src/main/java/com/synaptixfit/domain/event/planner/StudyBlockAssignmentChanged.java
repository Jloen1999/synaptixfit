package com.synaptixfit.domain.event.planner;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;

/**
 * Cambian los bloques asignados a unas tareas de reto (se crea, mueve de tarea o borra un bloque): su
 * progreso por bloques completados debe recalcularse (2/2 hechos → se añade otro → 2/3).
 */
public record StudyBlockAssignmentChanged(UUID userId, Set<UUID> milestoneIds, Instant occurredAt) implements DomainEvent {
}
