package com.synaptixfit.infrastructure.adapter.input.rest.dashboard.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import static com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.round;

import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.ActiveChallenge;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.NextTrainingDay;
import com.synaptixfit.domain.model.dashboard.SmartBanner;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.CognitiveStateResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.CrossRegulationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.WellbeingResponse;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Resumen del inicio. Los tipos de la BD se exponen como enums en UPPER_SNAKE_CASE (ver {@link #code}). */
public record DashboardResponse(GreetingResponse greeting, TodayResponse today, WeekResponse week,
                                CognitiveStateResponse cognitive, CrossRegulationResponse crossRegulation,
                                WellbeingResponse wellbeing, NextTrainingDayResponse nextTrainingDay,
                                List<ChallengeResponse> activeChallenges, List<PlanDayResponse> planWeek,
                                List<TodayEventResponse> todayEvents, BannerResponse banner) {

    private static final Map<String, String> CODES = Map.ofEntries(
            // tipo_actividad de horarios_academicos
            Map.entry("estudio", "STUDY"), Map.entry("deporte", "SPORT"), Map.entry("clase", "CLASS"),
            Map.entry("descanso", "REST"), Map.entry("comida", "MEAL"), Map.entry("sueno", "SLEEP"),
            Map.entry("examen", "EXAM"), Map.entry("entrega", "DELIVERY"), Map.entry("repaso", "REVIEW"),
            // tipo de entregas_examenes
            Map.entry("presentacion", "PRESENTATION"), Map.entry("otro", "OTHER"),
            // estado de dias_rutina
            Map.entry("pendiente", "PENDING"), Map.entry("en_progreso", "IN_PROGRESS"),
            Map.entry("completado", "COMPLETED"));

    /** Traduce un valor de la BD a su código de la API (desconocido: en mayúsculas). */
    static String code(String dbValue) {
        return dbValue == null ? null : CODES.getOrDefault(dbValue, dbValue.toUpperCase(java.util.Locale.ROOT));
    }

    public record GreetingResponse(String fullName, String avatarUrl, int level, int levelXp, int levelThreshold,
                                   int streak) {
    }

    public record TodayResponse(LocalDate date, double trainingCalories, double studyCalories, double totalCalories,
                                int sessions, int trainingMinutes, int studyMinutesCompleted, int studyMinutesPlanned,
                                double physicalLoad) {
    }

    @Schema(name = "DashboardWeekResponse")

    public record WeekResponse(LocalDate weekStart, int sessions, Integer plannedSessions, Integer remainingSessions,
                               int trainingMinutes, double trainingCalories, int studyMinutesCompleted) {
    }

    /** {@code status}: PENDING o IN_PROGRESS. */
    public record NextTrainingDayResponse(UUID routineId, String routineName, UUID weekId, int weekNumber, UUID dayId,
                                          int dayNumber, String dayName, String status) {

        static NextTrainingDayResponse from(NextTrainingDay d) {
            return d == null ? null : new NextTrainingDayResponse(d.routineId(), d.routineName(), d.weekId(),
                    d.weekNumber(), d.dayId(), d.dayNumber(), d.dayName(), code(d.dayStatus()));
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

    public record PlanDayResponse(LocalDate date, int planned, int completed) {
    }

    /**
     * {@code kind}: BLOCK o DEADLINE. {@code type}: STUDY, CLASS, REVIEW, SPORT, REST, MEAL, SLEEP (bloques)
     * o EXAM, DELIVERY, PRESENTATION, OTHER (entregas). {@code end} es null en las entregas.
     */
    public record TodayEventResponse(Dashboard.TodayEvent.Kind kind, UUID id, String title, String type, Instant start,
                                     Instant end, boolean completed, String subjectName) {
    }

    public record BannerResponse(SmartBanner.Type type, Map<String, Number> params) {
    }

    public static DashboardResponse from(Dashboard d) {
        Dashboard.TodayKpis t = d.today();
        Dashboard.WeekKpis w = d.week();
        return new DashboardResponse(
                new GreetingResponse(d.greeting().fullName(), d.greeting().avatarUrl(), d.greeting().level(),
                        d.greeting().levelXp(), d.greeting().levelThreshold(), d.greeting().streak()),
                new TodayResponse(t.date(), round(t.trainingCalories(), 1), round(t.studyCalories(), 1),
                        round(t.totalCalories(), 1), t.sessions(), t.trainingMinutes(), t.studyMinutesCompleted(),
                        t.studyMinutesPlanned(), round(t.physicalLoad(), 2)),
                new WeekResponse(w.weekStart(), w.sessions(), w.plannedSessions(), w.remainingSessions(),
                        w.trainingMinutes(), round(w.trainingCalories(), 1), w.studyMinutesCompleted()),
                CognitiveStateResponse.from(d.cognitive()),
                CrossRegulationResponse.from(d.crossRegulation()),
                WellbeingResponse.from(d.wellbeing()),
                NextTrainingDayResponse.from(d.nextTrainingDay()),
                d.activeChallenges().stream().map(ChallengeResponse::from).toList(),
                d.planWeek().stream().map(p -> new PlanDayResponse(p.date(), p.planned(), p.completed())).toList(),
                d.todayEvents().stream().map(e -> new TodayEventResponse(e.kind(), e.id(), e.title(), code(e.type()),
                        e.start(), e.end(), e.completed(), e.subjectName())).toList(),
                new BannerResponse(d.banner().type(), d.banner().params()));
    }
}
