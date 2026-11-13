package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.challenge.TaskMention;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.ActiveChallenge;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import com.synaptixfit.domain.model.training.PendingDay;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Resumen del inicio en una sola lectura. {@code nextDeadline}: la cuenta atrás de «Tu día» (ver
 * {@link #countdownOf}); nula si no hay nada pendiente.
 */
public record Dashboard(Greeting greeting, TodayKpis today, WeekKpis week, CognitiveState cognitive,
                        CrossRegulationView crossRegulation, WellbeingSnapshot wellbeing,
                        PendingDay nextTrainingDay, List<ActiveChallenge> activeChallenges,
                        List<PlanDay> planWeek, List<TodayEvent> todayEvents, SmartBanner banner,
                        Deadline nextDeadline) {

    /** Hasta dónde se busca la cuenta atrás: un curso entero, para que no tenga límite de días en la práctica. */
    public static final int COUNTDOWN_HORIZON_DAYS = 366;

    public Dashboard {
        activeChallenges = List.copyOf(activeChallenges);
        planWeek = List.copyOf(planWeek);
        todayEvents = List.copyOf(todayEvents);
    }

    /**
     * La cuenta atrás de «Tu día» (ADR 0038, regla en el servidor desde el ADR 0039): el próximo examen pendiente y,
     * si no hay ninguno, la próxima entrega pendiente. Un examen manda aunque haya entregas antes porque es lo que más
     * se prepara; lo vencido o hecho no cuenta.
     */
    public static Deadline countdownOf(List<Deadline> deadlines, Instant now) {
        List<Deadline> pending = deadlines.stream()
                .filter(d -> !d.completed() && !d.dueAt().isBefore(now))
                .sorted(Comparator.comparing(Deadline::dueAt))
                .toList();
        return pending.stream().filter(d -> d.kind() == DeadlineType.EXAM).findFirst()
                .orElse(pending.isEmpty() ? null : pending.getFirst());
    }

    /**
     * Saludo de Inicio. {@code birthday}: hoy (en su zona) es su cumpleaños y se enseña la tarjeta de felicitación
     * (ADR 0036; los nacidos el 29 de febrero, el 28 en los años no bisiestos).
     */
    public record Greeting(String fullName, String avatarUrl, int level, int levelXp, int levelThreshold, int streak,
                           boolean birthday) {

        public Greeting(String fullName, String avatarUrl, int level, int levelXp, int levelThreshold, int streak) {
            this(fullName, avatarUrl, level, levelXp, levelThreshold, streak, false);
        }
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

        /**
         * ¿Marcarlo registra carga física? Un deporte que no es el reflejo de un día de rutina: igual que en el
         * planificador ({@code CalendarBlock#countsAsPhysicalActivity}), así Inicio pide el esfuerzo como él.
         */
        public boolean tracksPhysicalLoad() {
            return kind == Kind.BLOCK && routineDayId == null
                    && ActivityType.fromCode(type) == ActivityType.SPORT;
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
