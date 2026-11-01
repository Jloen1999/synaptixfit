package com.synaptixfit.domain.model.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Bloque propuesto por las sugerencias de planificación (no se guarda: el usuario lo acepta creando
 * el bloque).
 *
 * @param type          {@link ActivityType#STUDY} o {@link ActivityType#SPORT}
 * @param routineWeekId semana del día de rutina asignado (deporte)
 * @param routineDayId  día de rutina asignado: el bloque refleja esa sesión (sin XP ni carga propias)
 * @param title         título propuesto («Semana 2 · Tirón»); nulo si no hay uno especial
 */
public record SuggestedBlock(ActivityType type, Instant start, Instant end, UUID subjectId, String subjectName,
                             UUID routineId, String routineName, String topic, UUID routineWeekId,
                             UUID routineDayId, String title) {

    public SuggestedBlock(ActivityType type, Instant start, Instant end, UUID subjectId, String subjectName,
                          UUID routineId, String routineName, String topic) {
        this(type, start, end, subjectId, subjectName, routineId, routineName, topic, null, null, null);
    }

    /** El mismo bloque enlazado a un día concreto de la rutina. */
    public SuggestedBlock forRoutineDay(RoutineRef routine, RoutineRef.Day day) {
        return new SuggestedBlock(type, start, end, subjectId, subjectName, routine.id(), routine.name(), topic,
                day.weekId(), day.id(), RoutineDistribution.title(routine, day));
    }

    /** El mismo bloque de deporte sin rutina (deporte libre). */
    public SuggestedBlock withoutRoutine() {
        return new SuggestedBlock(type, start, end, subjectId, subjectName, null, null, topic, null, null, null);
    }
}
