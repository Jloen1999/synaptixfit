package com.synaptixfit.domain.model.notification;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Lo que cuenta el correo del resumen semanal: la semana que termina y lo que viene en los próximos 7 días.
 *
 * @param plannedSessions sesiones del plan semanal de entrenamiento (null si no hay plan)
 * @param academic        la persona usa la parte de estudio (si no, no se habla de estudio ni de entregas)
 * @param fitness         la persona usa la parte de entrenamiento (si no, no se habla de entrenamientos)
 */
public record WeeklySummary(LocalDate weekStart, int studyMinutes, int trainingSessions, Integer plannedSessions,
                            int blocksCompleted, int blocksPlanned, int streak, List<Upcoming> upcoming,
                            boolean academic, boolean fitness) {

    /** Entrega o examen de la semana siguiente. */
    public record Upcoming(String title, Instant dueAt, boolean exam) {
    }

    /** Sin nada que contar (ni actividad ni fechas próximas): no se manda el correo. */
    public boolean isEmpty() {
        return studyMinutes == 0 && trainingSessions == 0 && blocksPlanned == 0 && upcoming.isEmpty();
    }
}
