package com.synaptixfit.domain.model.planner;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Reto (de Gamificación) al que se asigna un bloque, con su periodo. Un bloque de un reto o de una de sus
 * tareas debe caer dentro de ese periodo: fuera, la tarea nunca podría avanzar a tiempo (ADR 0028).
 */
public record ChallengeRef(UUID id, Instant startAt, Instant endAt) {

    /** ¿El día del bloque está entre el día de inicio y el de fin del reto (ambos incluidos)? */
    public boolean covers(Instant blockStart, PlannerZone zone) {
        LocalDate day = zone.localDate(blockStart);
        return !day.isBefore(zone.localDate(startAt)) && !day.isAfter(zone.localDate(endAt));
    }
}
