package com.synaptixfit.infrastructure.adapter.input.rest.dashboard.dto;

import static com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.round;

import com.synaptixfit.domain.model.challenge.TaskMention;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.ActiveChallenge;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.dashboard.SmartBanner;
import com.synaptixfit.domain.model.dashboard.TodaySummary;
import com.synaptixfit.domain.model.dashboard.WeekSummary;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PendingDay;
import com.synaptixfit.domain.model.training.TodayIntensity;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.CognitiveStateResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.CrossRegulationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.WellbeingResponse;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Resumen del inicio. Los tipos de la BD se exponen como enums en UPPER_SNAKE_CASE (ver {@link #code}).
 * {@code todayIntensity}: «Hoy toca: suave / normal / fuerte» (EASY, NORMAL, HARD); nulo si hoy no hay entreno.
 * ADR 0059: {@code weekSummary} («Tu semana» en una frase), {@code unfinishedSession} (sesión a medias que hay que
 * guardar o descartar; nula si no hay), {@code missedEvents} (lo de ayer sin marcar, el más reciente primero) y
 * {@code pendingFriendRequests} (solicitudes de amistad sin responder).
 */
public record DashboardResponse(GreetingResponse greeting, TodayResponse today, WeekResponse week,
                                CognitiveStateResponse cognitive, CrossRegulationResponse crossRegulation,
                                WellbeingResponse wellbeing, NextTrainingDayResponse nextTrainingDay,
                                List<ChallengeResponse> activeChallenges, List<PlanDayResponse> planWeek,
                                List<TodayEventResponse> todayEvents, BannerResponse banner,
                                NextDeadlineResponse nextDeadline, TodayIntensity todayIntensity,
                                TodaySummaryResponse todaySummary, WeekSummaryResponse weekSummary,
                                UnfinishedSessionResponse unfinishedSession, List<TodayEventResponse> missedEvents,
                                int pendingFriendRequests) {

    private static final Map<String, String> CODES = Map.ofEntries(
            // tipo_actividad de horarios_academicos
            Map.entry("estudio", "STUDY"), Map.entry("deporte", "SPORT"), Map.entry("clase", "CLASS"),
            Map.entry("descanso", "REST"), Map.entry("comida", "MEAL"), Map.entry("sueno", "SLEEP"),
            Map.entry("examen", "EXAM"), Map.entry("entrega", "DELIVERY"), Map.entry("repaso", "REVIEW"),
            Map.entry("personal", "PERSONAL"),
            // tipo de entregas_examenes
            Map.entry("presentacion", "PRESENTATION"), Map.entry("otro", "OTHER"));

    /** Traduce un valor de la BD a su código de la API (desconocido: en mayúsculas). */
    static String code(String dbValue) {
        return dbValue == null ? null : CODES.getOrDefault(dbValue, dbValue.toUpperCase(java.util.Locale.ROOT));
    }

    /** {@code birthday}: hoy es su cumpleaños (tarjeta de felicitación en Inicio, ADR 0036). */
    public record GreetingResponse(String fullName, String avatarUrl, int level, int levelXp, int levelThreshold,
                                   int streak, boolean birthday) {
    }

    public record TodayResponse(LocalDate date, double trainingCalories, double studyCalories, double totalCalories,
                                int sessions, int trainingMinutes, int studyMinutesCompleted, int studyMinutesPlanned,
                                double physicalLoad) {
    }

    @Schema(name = "DashboardWeekResponse")

    /** {@code studyMinutesPlanned}: estudio y repaso planificados en la semana («Estudio 5 h de 8 h»). */
    public record WeekResponse(LocalDate weekStart, int sessions, Integer plannedSessions, Integer remainingSessions,
                               int trainingMinutes, double trainingCalories, int studyMinutesCompleted,
                               int studyMinutesPlanned) {
    }

    /**
     * Próximo entrenamiento (regla única {@code RoutineSchedule}). {@code status}: PENDING o IN_PROGRESS;
     * {@code dayName} nulo si el día no tiene nombre propio (el cliente muestra el día de la semana de
     * {@code dayNumber}); {@code staleSessionId}: sesión abandonada de ese día que hay que cerrar antes;
     * {@code estimatedMinutes}: duración prevista del día («≈ 45 min»); {@code dueToday}: toca hoy o va con retraso
     * (sale en «Tu día» y no como «Próximo entreno», ADR 0059).
     */
    public record NextTrainingDayResponse(UUID routineId, String routineName, UUID weekId, int weekNumber,
                                          int totalWeeks, UUID dayId, int dayNumber, String dayName, String status,
                                          LocalDate scheduledDate, boolean overdue, int sessionOfWeek,
                                          int sessionsInWeek, UUID staleSessionId, int exerciseCount,
                                          int totalDays, int completedDays, int skippedDays, String coverImageUrl,
                                          Modality coverModality, int estimatedMinutes, boolean dueToday) {

        static NextTrainingDayResponse from(PendingDay p, boolean dueToday) {
            if (p == null) {
                return null;
            }
            Optional<ExerciseRef> cover = p.day().coverExercise();
            return new NextTrainingDayResponse(p.routine().id(), p.routine().name(), p.week().id(),
                    p.week().number(), p.routine().durationWeeks(), p.day().id(), p.day().number(), p.day().name(),
                    p.status().name(), p.scheduledDate(), p.overdue(), p.sessionOfWeek(), p.sessionsInWeek(),
                    p.staleSessionId(), p.day().exercises().size(), p.routine().totalDays(),
                    p.routine().completedDays(), p.routine().skippedDays(),
                    cover.map(ExerciseRef::stillImageUrl).orElse(null),
                    cover.map(ExerciseRef::modality).orElse(null),
                    p.day().estimatedMinutes(), dueToday);
        }
    }

    /** {@code type}: FITNESS o ACADEMIC; {@code difficulty}: LOW, MEDIUM o HIGH; {@code progress} 0-100. */
    @Schema(name = "DashboardChallengeResponse")
    public record ChallengeResponse(UUID id, String title, String type, String difficulty, Instant endsAt,
                                    double progress, int currentStreak) {

        static ChallengeResponse from(ActiveChallenge c) {
            return new ChallengeResponse(c.id(), c.title(), c.type().name(), c.difficulty().name(), c.endsAt(),
                    round(c.progress(), 1), c.currentStreak());
        }
    }

    /**
     * {@code mark}: NONE, DONE, PARTIAL, MISSED o PENDING (la marca del círculo, ADR 0059); {@code pending}: lo que
     * queda por hacer ese día.
     */
    public record PlanDayResponse(LocalDate date, int planned, int completed, int missed, Dashboard.DayMark mark,
                                  int pending) {
    }

    /** «Tu semana»: {@code done} de {@code planned} hechas, {@code missed} sin hacer y {@code state}. */
    public record WeekSummaryResponse(int done, int planned, int missed, WeekSummary.State state) {
    }

    /**
     * Sesión a medias: cuándo empezó y {@code exercisesDone} de {@code exercisesTotal} ejercicios (nulo si es
     * libre). {@code routineName}/{@code dayName}/{@code dayNumber} nulos en una sesión libre.
     */
    public record UnfinishedSessionResponse(UUID sessionId, String routineName, String dayName, Integer dayNumber,
                                            Instant startedAt, int exercisesDone, Integer exercisesTotal,
                                            String coverImageUrl) {

        static UnfinishedSessionResponse from(Dashboard.UnfinishedSession u) {
            return u == null ? null : new UnfinishedSessionResponse(u.sessionId(), u.routineName(), u.dayName(),
                    u.dayNumber(), u.startedAt(), u.exercisesDone(), u.exercisesTotal(), u.coverImageUrl());
        }
    }

    /**
     * {@code kind}: BLOCK o DEADLINE. {@code type}: STUDY, CLASS, REVIEW, SPORT, REST, MEAL, SLEEP, PERSONAL (bloques)
     * o EXAM, DELIVERY, PRESENTATION, OTHER (entregas). {@code end} es null en las entregas.
     */
    /**
     * {@code routineId}/{@code routineDayId}: día de rutina del bloque de deporte («Entrenar» empieza ese).
     * {@code tasks}: tareas de reto que avanzan al marcar este evento o esta entrega (ADR 0035).
     * {@code tracksPhysicalLoad}: al marcarlo se pide el esfuerzo, como en el planificador.
     * {@code place}: aula o lugar (el del evento o el habitual de su asignatura); {@code teacher}: profesor.
     */
    public record TodayEventResponse(Dashboard.TodayEvent.Kind kind, UUID id, String title, String type, Instant start,
                                     Instant end, boolean completed, String subjectName, ItemTimeStatus status,
                                     UUID routineId, UUID routineDayId, List<TaskMentionResponse> tasks,
                                     boolean tracksPhysicalLoad, String place, String teacher) {

        static TodayEventResponse from(Dashboard.TodayEvent e) {
            return new TodayEventResponse(e.kind(), e.id(), e.title(), code(e.type()), e.start(), e.end(),
                    e.completed(), e.subjectName(), e.status(), e.routineId(), e.routineDayId(),
                    e.tasks().stream().map(TaskMentionResponse::from).toList(), e.tracksPhysicalLoad(), e.place(),
                    e.teacher());
        }
    }

    /** Tarea de reto que avanza con un evento; {@code title} nulo: el propio reto (sin tareas, va con su entrega). */
    public record TaskMentionResponse(UUID challengeId, String challengeTitle, UUID milestoneId, String title) {

        public static TaskMentionResponse from(TaskMention t) {
            return new TaskMentionResponse(t.challengeId(), t.challengeTitle(), t.milestoneId(), t.title());
        }
    }

    /**
     * Cuenta atrás de «Tu día»: el próximo examen pendiente o, si no hay, la próxima entrega (la regla es del
     * servidor, ADR 0039). {@code type}: EXAM, ASSIGNMENT, PRESENTATION u OTHER.
     */
    @Schema(name = "DashboardNextDeadlineResponse")
    public record NextDeadlineResponse(UUID id, String title, String type, Instant dueAt, String subjectName) {

        static NextDeadlineResponse from(Deadline d) {
            // El mismo vocabulario que la API de entregas (DeadlineType), no el de los bloques.
            return d == null ? null
                    : new NextDeadlineResponse(d.id(), d.title(), d.kind().name(), d.dueAt(), d.subjectName());
        }
    }

    /**
     * Resumen de «Tu día» (ADR 0050): el anillo ({@code done} de {@code total}, sin clases y con las entregas de hoy),
     * lo que quedó sin hacer ({@code missed}), el evento que se destaca ({@code nextEventId}, uno de {@code todayEvents};
     * nulo si no queda nada) y {@code state}: NOTHING_PLANNED, PENDING, MISSED_LEFT o ALL_DONE.
     * {@code spotlightEventId}: el evento de la fila «ahora o a continuación» (clases incluidas, ADR 0059); nulo si no hay.
     */
    public record TodaySummaryResponse(int done, int total, int missed, UUID nextEventId, TodaySummary.State state,
                                       UUID spotlightEventId) {

        static TodaySummaryResponse from(TodaySummary s, UUID spotlightEventId) {
            return new TodaySummaryResponse(s.done(), s.total(), s.missed(), s.nextEventId(), s.state(),
                    spotlightEventId);
        }
    }

    /** {@code labels}: textos del usuario que el aviso cita (p. ej. el bloque sin hacer). */
    public record BannerResponse(SmartBanner.Type type, Map<String, Number> params, Map<String, String> labels) {
    }

    public static DashboardResponse from(Dashboard d) {
        Dashboard.TodayKpis t = d.today();
        Dashboard.WeekKpis w = d.week();
        return new DashboardResponse(
                new GreetingResponse(d.greeting().fullName(), d.greeting().avatarUrl(), d.greeting().level(),
                        d.greeting().levelXp(), d.greeting().levelThreshold(), d.greeting().streak(),
                        d.greeting().birthday()),
                new TodayResponse(t.date(), round(t.trainingCalories(), 1), round(t.studyCalories(), 1),
                        round(t.totalCalories(), 1), t.sessions(), t.trainingMinutes(), t.studyMinutesCompleted(),
                        t.studyMinutesPlanned(), round(t.physicalLoad(), 2)),
                new WeekResponse(w.weekStart(), w.sessions(), w.plannedSessions(), w.remainingSessions(),
                        w.trainingMinutes(), round(w.trainingCalories(), 1), w.studyMinutesCompleted(),
                        d.extras().studyMinutesPlannedWeek()),
                CognitiveStateResponse.from(d.cognitive()),
                CrossRegulationResponse.from(d.crossRegulation()),
                WellbeingResponse.from(d.wellbeing()),
                NextTrainingDayResponse.from(d.nextTrainingDay(), d.extras().trainingDueToday()),
                d.activeChallenges().stream().map(ChallengeResponse::from).toList(),
                d.planWeek().stream()
                        .map(p -> new PlanDayResponse(p.date(), p.planned(), p.completed(), p.missed(), p.mark(),
                                p.pending())).toList(),
                d.todayEvents().stream().map(TodayEventResponse::from).toList(),
                new BannerResponse(d.banner().type(), d.banner().params(), d.banner().labels()),
                NextDeadlineResponse.from(d.nextDeadline()),
                d.todayIntensity(),
                TodaySummaryResponse.from(d.todaySummary(), d.spotlightEventId()),
                weekSummary(d.weekSummary()),
                UnfinishedSessionResponse.from(d.extras().unfinishedSession()),
                d.extras().missedEvents().stream().map(TodayEventResponse::from).toList(),
                d.extras().pendingFriendRequests());
    }

    private static WeekSummaryResponse weekSummary(WeekSummary w) {
        return new WeekSummaryResponse(w.done(), w.planned(), w.missed(), w.state());
    }
}
