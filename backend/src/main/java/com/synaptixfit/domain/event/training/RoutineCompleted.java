package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Se ha terminado un ciclo de una rutina (todos sus días hechos o saltados). Notificaciones avisa
 * del logro (uno por ciclo) y Gamificación evalúa insignias.
 *
 * @param cycleStart fecha de inicio del ciclo (distingue un ciclo repetido del anterior)
 */
public record RoutineCompleted(UUID userId, UUID routineId, String routineName, LocalDate cycleStart,
                               Instant occurredAt) implements DomainEvent {
}
