package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.training.TrainingSession;
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
     */
    public record CalendarBlock(UUID id, String activityType, Instant start, Instant end, boolean completed,
                                String subjectName, String topics) {
    }

    /** Entrega o examen. {@code type} en la BD: 'examen', 'entrega', 'presentacion', 'otro'. */
    public record Deadline(UUID id, String title, String type, Instant dueAt, boolean completed, String subjectName) {
    }

    /** Primer día no completado de la rutina activa más reciente. */
    /**
     * @param openSessionStartedAt inicio de la sesión sin terminar más reciente de ese día (null si no hay)
     */
    public record NextTrainingDay(UUID routineId, String routineName, UUID weekId, int weekNumber, UUID dayId,
                                  int dayNumber, String dayName, String dayStatus, Instant openSessionStartedAt) {

        public NextTrainingDay(UUID routineId, String routineName, UUID weekId, int weekNumber, UUID dayId,
                               int dayNumber, String dayName, String dayStatus) {
            this(routineId, routineName, weekId, weekNumber, dayId, dayNumber, dayName, dayStatus, null);
        }

        /**
         * El día solo sigue «en curso» si su sesión abierta no está abandonada
         * ({@link TrainingSession#STALE_AFTER}); si no, vuelve a estar pendiente.
         */
        public NextTrainingDay effective(Instant now) {
            boolean inProgress = IN_PROGRESS.equals(dayStatus);
            boolean stale = openSessionStartedAt == null || TrainingSession.isStaleStart(openSessionStartedAt, now);
            return inProgress && stale
                    ? new NextTrainingDay(routineId, routineName, weekId, weekNumber, dayId, dayNumber, dayName,
                            PENDING, openSessionStartedAt)
                    : this;
        }

        static final String IN_PROGRESS = "en_progreso";
        static final String PENDING = "pendiente";
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
