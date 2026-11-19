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
import com.synaptixfit.domain.model.training.TodayIntensity;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Resumen del inicio en una sola lectura. {@code nextDeadline}: la cuenta atrás de «Tu día» (ver
 * {@link #countdownOf}); nula si no hay nada pendiente. {@code todayIntensity}: «Hoy toca: suave / normal / fuerte»,
 * nula si hoy no hay entreno por hacer ({@link #trainsToday}).
 */
public record Dashboard(Greeting greeting, TodayKpis today, WeekKpis week, CognitiveState cognitive,
                        CrossRegulationView crossRegulation, WellbeingSnapshot wellbeing,
                        PendingDay nextTrainingDay, List<ActiveChallenge> activeChallenges,
                        List<PlanDay> planWeek, List<TodayEvent> todayEvents, SmartBanner banner,
                        Deadline nextDeadline, TodayIntensity todayIntensity, Extras extras) {

    /** Hasta dónde se busca la cuenta atrás: un curso entero, para que no tenga límite de días en la práctica. */
    public static final int COUNTDOWN_HORIZON_DAYS = 366;

    public Dashboard {
        activeChallenges = List.copyOf(activeChallenges);
        planWeek = List.copyOf(planWeek);
        todayEvents = List.copyOf(todayEvents);
        extras = extras == null ? Extras.NONE : extras;
    }

    /** Resumen de «Tu día» (ADR 0050): sale de los mismos eventos que la agenda, así nunca se contradicen. */
    public TodaySummary todaySummary() {
        return TodaySummary.of(todayEvents);
    }

    /** Evento que nombra la fila de «Tu día» (ADR 0059): ver {@link TodaySpotlight}. */
    public UUID spotlightEventId() {
        return TodaySpotlight.of(todayEvents);
    }

    /** Cómo va la semana («Tu semana», ADR 0059), con los mismos días que {@link #planWeek}. */
    public WeekSummary weekSummary() {
        return WeekSummary.of(planWeek);
    }

    /**
     * Lo que Inicio añade en el ADR 0059.
     *
     * @param trainingDueToday        el próximo día de rutina toca hoy o va con retraso: sale en «Tu día», no aparte
     * @param unfinishedSession       sesión a medias que hay que guardar o descartar (la más reciente); nula si no hay
     * @param missedEvents            eventos de ayer que pasaron sin marcar, el más reciente primero
     * @param pendingFriendRequests   solicitudes de amistad recibidas sin responder (icono «Comunidad»)
     * @param studyMinutesPlannedWeek minutos de estudio y repaso planificados en la semana («Estudio 5 h de 8 h»)
     */
    public record Extras(boolean trainingDueToday, UnfinishedSession unfinishedSession, List<TodayEvent> missedEvents,
                         int pendingFriendRequests, int studyMinutesPlannedWeek) {

        public static final Extras NONE = new Extras(false, null, List.of(), 0, 0);

        public Extras {
            missedEvents = missedEvents == null ? List.of() : List.copyOf(missedEvents);
        }
    }

    /**
     * Sesión de entreno a medias (ADR 0059): abierta más de 6 h ({@code TrainingSession#isLeftover}).
     * {@code exercisesDone} de {@code exercisesTotal} (nulo en una sesión libre).
     */
    public record UnfinishedSession(UUID sessionId, String routineName, String dayName, Integer dayNumber,
                                    Instant startedAt, int exercisesDone, Integer exercisesTotal,
                                    String coverImageUrl) {
    }

    /**
     * ¿Hay entreno hoy por hacer? (ADR 0042: solo entonces sale «Hoy toca» en «Tu día»). Sí si el próximo día de la
     * rutina toca hoy o va con retraso, o si hoy hay un evento de deporte sin marcar.
     */
    public static boolean trainsToday(PendingDay next, List<TodayEvent> todayEvents, LocalDate today) {
        boolean routineDay = next != null && next.isDueBy(today);
        return routineDay || todayEvents.stream().anyMatch(e -> e.kind() == TodayEvent.Kind.BLOCK
                && ActivityType.SPORT.code().equals(e.type()) && !e.completed());
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

    /**
     * Bloques planificados y completados de un día de la semana (sin descanso, comida ni sueño); {@code missed}: los
     * que ya pasaron sin hacerse.
     */
    public record PlanDay(LocalDate date, int planned, int completed, int missed) {

        public PlanDay(LocalDate date, int planned, int completed) {
            this(date, planned, completed, 0);
        }

        /** Lo que queda por hacer ese día (ni hecho ni pasado sin hacer). */
        public int pending() {
            return Math.max(0, planned - completed - missed);
        }

        /**
         * Marca del día en «Tu semana» (ADR 0059), que se entiende sin color: nada planificado; todo hecho; algo se
         * quedó sin hacer (manda sobre lo demás: es lo que aún se puede recuperar); a medias (algo hecho y algo por
         * hacer); o solo por hacer (el cliente pinta cuántos quedan, {@link #pending}).
         */
        public DayMark mark() {
            if (planned == 0) {
                return DayMark.NONE;
            }
            if (completed >= planned) {
                return DayMark.DONE;
            }
            if (missed > 0) {
                return DayMark.MISSED;
            }
            return completed > 0 ? DayMark.PARTIAL : DayMark.PENDING;
        }
    }

    /** Marca de un día de «Tu semana». */
    public enum DayMark { NONE, DONE, PARTIAL, MISSED, PENDING }

    /**
     * Evento de hoy: un bloque del calendario o una entrega/examen. {@code type}: tipo de actividad del bloque o de la
     * entrega, tal cual en la BD; {@code end}: fin del bloque (null en entregas); {@code status}: pendiente, en curso,
     * hecho o no hecho/vencido ({@link ItemTimeStatus}); {@code routineId}/{@code routineDayId}: día de rutina que
     * refleja un bloque de deporte; {@code place}: aula o lugar ({@code CalendarBlock#where}); {@code teacher}:
     * profesor de su asignatura.
     */
    public record TodayEvent(Kind kind, UUID id, String title, String type, Instant start, Instant end,
                             boolean completed, String subjectName, ItemTimeStatus status, UUID routineId,
                             UUID routineDayId, List<TaskMention> tasks, String place, String teacher) {

        public enum Kind { BLOCK, DEADLINE }

        public TodayEvent {
            tasks = tasks == null ? List.of() : List.copyOf(tasks);
        }

        public TodayEvent(Kind kind, UUID id, String title, String type, Instant start, Instant end,
                          boolean completed, String subjectName, ItemTimeStatus status, UUID routineId,
                          UUID routineDayId, List<TaskMention> tasks) {
            this(kind, id, title, type, start, end, completed, subjectName, status, routineId, routineDayId, tasks,
                    null, null);
        }

        /** El mismo evento diciendo dónde es y quién da la clase. */
        public TodayEvent withPlace(String where, String teacherName) {
            return new TodayEvent(kind, id, title, type, start, end, completed, subjectName, status, routineId,
                    routineDayId, tasks, where, teacherName);
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
                    routineDayId, advanced, place, teacher);
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
