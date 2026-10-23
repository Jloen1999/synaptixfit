package com.synaptixfit.domain.model.planner;

import java.util.List;
import java.util.UUID;

/**
 * Rutina de entrenamiento vista desde el planificador (la gestiona el módulo de entrenamiento).
 *
 * @param days días de la rutina en orden (semana 1 día 1, semana 1 día 2…); vacía si no se pidieron
 */
public record RoutineRef(UUID id, String name, String goal, int weeks, int exerciseCount, List<Day> days) {

    public RoutineRef {
        days = days == null ? List.of() : List.copyOf(days);
    }

    /** Día de la rutina con la semana a la que pertenece. */
    public record Day(UUID id, UUID weekId, int weekNumber, int dayNumber, String name) {
    }
}
