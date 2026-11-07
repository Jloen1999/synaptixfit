package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.challenge.TaskMention;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.ActiveChallenge;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import com.synaptixfit.domain.model.training.PendingDay;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Resumen del inicio en una sola lectura. */
public record Dashboard(Greeting greeting, TodayKpis today, WeekKpis week, CognitiveState cognitive,
                        CrossRegulationView crossRegulation, WellbeingSnapshot wellbeing,
                        PendingDay nextTrainingDay, List<ActiveChallenge> activeChallenges,
                        List<PlanDay> planWeek, List<TodayEvent> todayEvents, SmartBanner banner) {

    public Dashboard {
        activeChallenges = List.copyOf(activeChallenges);
        planWeek = List.copyOf(planWeek);
        todayEvents = List.copyOf(todayEvents);
    }

    public record Greeting(String fullName, String avatarUrl, int level, int levelXp, int levelThreshold, int streak) {
    }

    /** KPIs de hoy. Las calorías de estudio salen de la fórmula 1. */
    public record TodayKpis(LocalDate date, double trainingCalories, double studyCalories, int sessions,
                            int trainingMinutes, int studyMinutesCompleted, int studyMinutesPlanned,
                            double physicalLoad) {

        public double totalCalories() {
            return trainingCalories + studyCalories;
        }
    }

    /**
     * KPIs de la semana en curso (lunes a domingo).
     *
     * @param plannedSessions sesiones del plan de entrenamiento semanal activo (null sin plan)
     */
    public record WeekKpis(LocalDate weekStart, int sessions, Integer plannedSessions, Integer remainingSessions,
                           int trainingMinutes, double trainingCalories, int studyMinutesCompleted) {
    }

    /** Bloques planificados y completados de un día de la semana (sin descanso, comida ni sueño). */
    /** {@code missed}: bloques del día que ya pasaron sin hacerse. */
    public record PlanDay(LocalDate date, int planned, int completed, int missed) {

        public PlanDay(LocalDate date, int planned, int completed) {
            this(date, planned, completed, 0);
        }
    }

    /**
     * Evento de hoy: un bloque del calendario o una entrega/examen.
     *
     * @param type tipo de actividad del bloque o tipo de la entrega, tal cual en la BD
     * @param end  fin del bloque (null en entregas)
     */
    /**
     * {@code status}: pendiente, en curso, hecho o no hecho/vencido ({@link ItemTimeStatus});
     * {@code routineId}/{@code routineDayId}: día de rutina que refleja un bloque de deporte.
     */
    public record TodayEvent(Kind kind, UUID id, String title, String type, Instant start, Instant end,
                             boolean completed, String subjectName, ItemTimeStatus status, UUID routineId,
                             UUID routineDayId, List<TaskMention> tasks) {

        public enum Kind { BLOCK, DEADLINE }

        public TodayEvent {
            tasks = tasks == null ? List.of() : List.copyOf(tasks);
        }

        public TodayEvent(Kind kind, UUID id, String title, String type, Instant start, Instant end,
                          boolean completed, String subjectName, ItemTimeStatus status, UUID routineId,
                          UUID routineDayId) {
            this(kind, id, title, type, start, end, completed, subjectName, status, routineId, routineDayId,
                    List.of());
        }

        /** El mismo evento diciendo qué tareas de reto hace avanzar (ADR 0035). */
        public TodayEvent withTasks(List<TaskMention> advanced) {
            return new TodayEvent(kind, id, title, type, start, end, completed, subjectName, status, routineId,
                    routineDayId, advanced);
        }

        public TodayEvent(Kind kind, UUID id, String title, String type, Instant start, Instant end,
                          boolean completed, String subjectName, ItemTimeStatus status) {
            this(kind, id, title, type, start, end, completed, subjectName, status, null, null);
        }

        public TodayEvent(Kind kind, UUID id, String title, String type, Instant start, Instant end,
                          boolean completed, String subjectName) {
            this(kind, id, title, type, start, end, completed, subjectName,
                    completed ? ItemTimeStatus.DONE : ItemTimeStatus.UPCOMING);
        }
    }
}
