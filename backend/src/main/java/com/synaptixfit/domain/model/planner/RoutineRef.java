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

    /** Días que aún quedan por entrenar, en orden. */
    public List<Day> pendingDays() {
        return days.stream().filter(Day::pending).toList();
    }

    /**
     * Sesiones que quedan de la semana de la rutina en la que se va (la del primer día pendiente): el
     * objetivo semanal de entrenamiento sale de la rutina, no de un número aparte. 0 si no quedan.
     */
    public int pendingDaysInCurrentWeek() {
        List<Day> pending = pendingDays();
        if (pending.isEmpty()) {
            return 0;
        }
        int week = pending.getFirst().weekNumber();
        return (int) pending.stream().filter(d -> d.weekNumber() == week).count();
    }

    /**
     * Día de la rutina con la semana a la que pertenece.
     *
     * @param dayNumber día de la semana preferido (1 = lunes)
     * @param pending   tiene ejercicios y no está hecho ni saltado (lo decide Entrenamiento)
     */
    public record Day(UUID id, UUID weekId, int weekNumber, int dayNumber, String name, boolean pending) {

        public Day(UUID id, UUID weekId, int weekNumber, int dayNumber, String name) {
            this(id, weekId, weekNumber, dayNumber, name, true);
        }
    }
}
