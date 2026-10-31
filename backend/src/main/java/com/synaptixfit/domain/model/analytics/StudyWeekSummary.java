package com.synaptixfit.domain.model.analytics;

import com.synaptixfit.domain.model.planner.PlannerProfile;
import java.time.LocalDate;

/**
 * Cómo va el estudio esta semana (de lunes, en la zona de la app): minutos de concentración del
 * Pomodoro (por su día registrado), bloques de estudio hechos frente a planificados, repasos y
 * simulacros. Es la tarjeta «Tu estudio» de Progreso, equivalente académico del resumen de
 * entrenamiento. Los minutos son solo los del Pomodoro, no la actividad de estudio completa de
 * {@code StudyActivity}.
 *
 * @param averageTestScore porcentaje de aciertos de los simulacros terminados (aciertos / preguntas
 *                         de todos ellos, 0-100); null sin simulacros
 * @param reviewsDue       materiales con el repaso ya pendiente hoy
 * @param studyHours       horas reales de estudio de la semana (bloques hechos y concentración sin bloque, las
 *                         mismas que cuentan para el bonus semanal)
 * @param weeklyGoalHours  objetivo semanal del perfil académico (o el de por defecto): antes se pedía en el perfil
 *                         y no se mostraba en ningún sitio
 */
public record StudyWeekSummary(LocalDate weekStart, int focusMinutes, int focusSessions, int studyBlocksPlanned,
                               int studyBlocksCompleted, int reviewsCompleted, int testsCompleted,
                               Integer averageTestScore, int reviewsDue, int studyHours, int weeklyGoalHours) {

    /** Recuentos en bruto que trae la persistencia; las proporciones las calcula {@link #of}. */
    public record Counts(int focusMinutes, int focusSessions, int studyBlocksPlanned, int studyBlocksCompleted,
                         int reviewsCompleted, int testsCompleted, int testCorrectAnswers, int testQuestions,
                         int reviewsDue, int studyHours, Integer goalHours) {
    }

    public static StudyWeekSummary of(LocalDate weekStart, Counts c) {
        Integer score = c.testQuestions() <= 0 ? null
                : (int) Math.round(100.0 * c.testCorrectAnswers() / c.testQuestions());
        int goal = c.goalHours() == null ? PlannerProfile.Academic.DEFAULT_WEEKLY_GOAL_HOURS : c.goalHours();
        return new StudyWeekSummary(weekStart, c.focusMinutes(), c.focusSessions(), c.studyBlocksPlanned(),
                c.studyBlocksCompleted(), c.reviewsCompleted(), c.testsCompleted(), score, c.reviewsDue(),
                c.studyHours(), goal);
    }

    /** Porcentaje de bloques de estudio hechos; null si esta semana no se planificó ninguno. */
    public Integer planAdherence() {
        return studyBlocksPlanned <= 0 ? null
                : (int) Math.round(100.0 * Math.min(studyBlocksCompleted, studyBlocksPlanned) / studyBlocksPlanned);
    }

    /** Sin nada que contar todavía (la tarjeta invita a empezar); los repasos pendientes sí cuentan. */
    public boolean isEmpty() {
        return focusMinutes == 0 && studyBlocksPlanned == 0 && reviewsCompleted == 0 && testsCompleted == 0
                && reviewsDue == 0;
    }
}
