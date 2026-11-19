package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.planner.DeadlineType;
import java.time.Instant;
import java.util.UUID;

/** Modelos de lectura que el inicio obtiene de otros módulos (entrenamiento, planificador, gamificación). */
public final class DashboardReadModels {

    private DashboardReadModels() {
    }

    /** Sesiones registradas en un intervalo. */
    public record TrainingTotals(int sessions, int minutes, double calories) {
    }

    /**
     * Bloque del calendario.
     *
     * @param activityType tipo en la BD ('estudio', 'clase', 'deporte', 'repaso', …)
     * @param routineId    rutina enlazada (bloques de deporte de una rutina)
     * @param routineDayId día de rutina que refleja el bloque: «Entrenar» empieza ese día
     * @param milestoneId  tarea de reto a la que está asignado (la hace avanzar)
     * @param place        aula o lugar del propio evento (el del horario importado), si lo tiene
     * @param subjectRoom  aula habitual de su asignatura (ADR 0036)
     * @param teacher      profesor o profesora de su asignatura
     */
    public record CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                                String subjectName, String topics, UUID routineId, UUID routineDayId,
                                UUID milestoneId, String place, String subjectRoom, String teacher) {

        public CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                             String subjectName, String topics) {
            this(id, activityType, start, end, completed, subjectName, topics, null, null, null);
        }

        public CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                             String subjectName, String topics, UUID routineId, UUID routineDayId) {
            this(id, activityType, start, end, completed, subjectName, topics, routineId, routineDayId, null);
        }

        public CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                             String subjectName, String topics, UUID routineId, UUID routineDayId,
                             UUID milestoneId) {
            this(id, activityType, start, end, completed, subjectName, topics, routineId, routineDayId, milestoneId,
                    null, null, null);
        }

        /**
         * Dónde es: el aula del propio evento y, si no la trae, la habitual de su asignatura (la misma regla que la
         * tarjeta de la asignatura, {@code SubjectAgenda}). Nulo si no se sabe.
         */
        public String where() {
            if (place != null && !place.isBlank()) {
                return place.strip();
            }
            return subjectRoom == null || subjectRoom.isBlank() ? null : subjectRoom.strip();
        }

        /** Profesor de su asignatura, sin espacios sobrantes; nulo si no se sabe. */
        public String teacherName() {
            return teacher == null || teacher.isBlank() ? null : teacher.strip();
        }
    }

    /**
     * Entrega o examen. {@code type} en la BD: 'examen', 'entrega', 'presentacion', 'otro' (los eventos de hoy lo
     * exponen así); {@code kind} es el mismo tipo en el dominio, para las reglas (cuenta atrás) y la API.
     */
    public record Deadline(UUID id, String title, String type, Instant dueAt, boolean completed, String subjectName,
                           DeadlineType kind) {
    }

    /**
     * Reto activo destacado.
     *
     * @param progress porcentaje 0-100, siempre el de {@link Challenge#progress()}
     */
    public record ActiveChallenge(UUID id, String title, ChallengeType type, Difficulty difficulty, Instant endsAt,
                                  double progress, int currentStreak) {

        public static ActiveChallenge of(Challenge c) {
            return new ActiveChallenge(c.id(), c.title(), c.type(), c.difficulty(), c.endAt(), c.progress(),
                    c.currentStreak());
        }
    }
}
