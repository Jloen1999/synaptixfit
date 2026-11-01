package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
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
     */
    public record CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                                String subjectName, String topics, UUID routineId, UUID routineDayId) {

        public CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                             String subjectName, String topics) {
            this(id, activityType, start, end, completed, subjectName, topics, null, null);
        }
    }

    /** Entrega o examen. {@code type} en la BD: 'examen', 'entrega', 'presentacion', 'otro'. */
    public record Deadline(UUID id, String title, String type, Instant dueAt, boolean completed, String subjectName) {
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
