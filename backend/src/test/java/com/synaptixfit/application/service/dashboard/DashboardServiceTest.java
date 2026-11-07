package com.synaptixfit.application.service.dashboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyActivityUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import com.synaptixfit.domain.model.dashboard.SmartBanner;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.PhysicalLoadSummary;
import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DashboardServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-14T12:00:00Z"); // miércoles
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 14);
    private static final LocalDate MONDAY = LocalDate.of(2026, 10, 12);

    private final UserRepositoryPort users = mock(UserRepositoryPort.class);
    private final DashboardReadPort reads = mock(DashboardReadPort.class);
    private final InsightsSourcePort sources = mock(InsightsSourcePort.class);
    private final GetCrossRegulationUseCase regulation = mock(GetCrossRegulationUseCase.class);
    private DashboardService service;

    @BeforeEach
    void setUp() {
        GetCognitiveStateUseCase cognitive = (u, tz) -> CognitiveState.initial(u, NOW);
        GetStudyCaloriesTodayUseCase calories = (u, tz) -> new StudyCaloriesSummary(TODAY, 42.0, 1, 60);
        GetPhysicalLoadUseCase load = (u, tz) -> new PhysicalLoadSummary(TODAY, 300, 600, 0.5, List.of());
        GetWellbeingUseCase wellbeing = (u, tz) -> new WellbeingSnapshot(TODAY, false, null, null, null, null, null);
        CrossRegulationState optimal = CrossRegulationState.compute(USER, 2100, 8400, null, NOW);
        when(regulation.getCrossRegulation(eq(USER), any()))
                .thenReturn(new CrossRegulationView(optimal, optimal.acwr(), optimal.zone(), 0, 1.0));
        when(users.findById(USER)).thenReturn(Optional.of(User.builder().id(USER).email("a@b.com").fullName("Ana")
                .level(3).levelXp(120).streak(2).privacy(Visibility.PRIVATE).role(Role.USER).passwordHash("x")
                .createdAt(NOW).build()));
        when(reads.trainingTotals(eq(USER), any(), any())).thenReturn(new TrainingTotals(1, 45, 350.0));
        when(reads.plannedWeeklySessions(eq(USER), any())).thenReturn(Optional.of(4));
        when(reads.lastTrainingSession(USER)).thenReturn(Optional.of(NOW));
        when(sources.checkIns(eq(USER), any(), any())).thenReturn(List.of());
        when(sources.completedStudyBlocks(eq(USER), any(), any())).thenReturn(List.of());
        // Reto de fitness por sesiones: 1 de 4 hechas; el progreso debe salir de Challenge.progress().
        Challenge fitness = Challenge.builder().id(UUID.randomUUID()).ownerId(USER).title("Entrenar 4 veces")
                .type(ChallengeType.FITNESS).startAt(NOW.minusSeconds(86400)).endAt(NOW.plusSeconds(86400))
                .createdAt(NOW).sessionTarget(4).sessionsCompleted(1).build();
        ListMyChallengesUseCase challenges = (u, query, page) -> {
            assertThat(query.status()).isEqualTo(ChallengeStatus.ACTIVE);
            assertThat(page.size()).isEqualTo(DashboardService.MAX_CHALLENGES);
            return new PageResult<>(List.of(fitness), 0, page.size(), 1);
        };
        // Actividad de la semana: un bloque completado de 60 min y un Pomodoro suelto de 25 min.
        Instant mondayStudy = Instant.parse("2026-10-12T09:00:00Z");
        GetStudyActivityUseCase studyActivity = (u, from, to) -> {
            assertThat(from).isEqualTo(Instant.parse("2026-10-12T00:00:00Z"));
            assertThat(to).isEqualTo(Instant.parse("2026-10-19T00:00:00Z"));
            return List.of(new CompletedStudyBlock(UUID.randomUUID(), "estudio", mondayStudy,
                            mondayStudy.plusSeconds(3600), 3, null),
                    CompletedStudyBlock.focus(UUID.randomUUID(), mondayStudy.plusSeconds(7200), 25, null));
        };
        service = new DashboardService(users, reads, sources, cognitive, regulation, calories, studyActivity, load,
                wellbeing, challenges, userId -> Optional.empty(), Clock.fixed(NOW, ZoneOffset.UTC), ZoneId.of("UTC"));
    }

    @Test
    void composesKpisPlanWeekEventsAndBanner() {
        Instant todayStudy = Instant.parse("2026-10-14T09:00:00Z");
        Instant mondayStudy = Instant.parse("2026-10-12T09:00:00Z");
        when(reads.calendarBlocks(eq(USER), any(), any())).thenReturn(List.of(
                new CalendarBlock(UUID.randomUUID(), "estudio", mondayStudy, mondayStudy.plusSeconds(3600), true, "Cálculo", null),
                new CalendarBlock(UUID.randomUUID(), "comida", mondayStudy.plusSeconds(10800), mondayStudy.plusSeconds(12600), false, null, null),
                new CalendarBlock(UUID.randomUUID(), "estudio", todayStudy, todayStudy.plusSeconds(5400), false, "Física", "Ondas"),
                new CalendarBlock(UUID.randomUUID(), "examen", todayStudy.plusSeconds(18000), todayStudy.plusSeconds(21600), false, "Física", null)));
        when(reads.deadlines(eq(USER), any(), any())).thenReturn(List.of(
                new Deadline(UUID.randomUUID(), "Examen Física", "examen", Instant.parse("2026-10-14T14:00:00Z"), false, "Física"),
                new Deadline(UUID.randomUUID(), "Práctica", "entrega", Instant.parse("2026-10-17T23:00:00Z"), false, null)));

        Dashboard d = service.getDashboard(USER, null);

        assertThat(d.greeting().fullName()).isEqualTo("Ana");
        assertThat(d.greeting().levelThreshold()).isEqualTo(300);
        assertThat(d.today().totalCalories()).isEqualTo(392.0);
        // Definición única de actividad cognitiva (planificador): el examen también cuenta (90 + 60).
        assertThat(d.today().studyMinutesPlanned()).isEqualTo(150);
        assertThat(d.week().remainingSessions()).isEqualTo(3);
        // Bloque + Pomodoro de la semana (GetStudyActivityUseCase), no solo los bloques del calendario.
        assertThat(d.week().studyMinutesCompleted()).isEqualTo(85);
        assertThat(d.planWeek()).hasSize(7);
        assertThat(d.planWeek().get(0)).isEqualTo(new Dashboard.PlanDay(MONDAY, 1, 1)); // la comida no cuenta
        // Uno de los dos de hoy ya terminó sin hacerse: «no hecho».
        assertThat(d.planWeek().get(2)).isEqualTo(new Dashboard.PlanDay(TODAY, 2, 0, 1));
        // El bloque de examen no se duplica: aparece la entrega/examen.
        assertThat(d.todayEvents()).extracting(Dashboard.TodayEvent::kind)
                .containsExactly(Dashboard.TodayEvent.Kind.BLOCK, Dashboard.TodayEvent.Kind.DEADLINE);
        assertThat(d.activeChallenges()).singleElement().satisfies(c -> {
            assertThat(c.progress()).isEqualTo(25.0);
            assertThat(c.type()).isEqualTo(ChallengeType.FITNESS);
        });
        assertThat(d.banner().type()).isEqualTo(SmartBanner.Type.UPCOMING_DEADLINES);
        assertThat(d.banner().params()).containsEntry("count", 2).containsEntry("daysUntilNext", 0);
    }

    @Test
    void withoutSignalsTheBannerAsksForTheCheckIn() {
        when(reads.calendarBlocks(eq(USER), any(), any())).thenReturn(List.of());
        when(reads.deadlines(eq(USER), any(), any())).thenReturn(List.of());
        assertThat(service.getDashboard(USER, "UTC").banner().type()).isEqualTo(SmartBanner.Type.CHECK_IN_PENDING);
    }

    @Test
    void unknownUserIsNotFound() {
        assertThatThrownBy(() -> service.getDashboard(UUID.randomUUID(), null)).isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void studyStreakCountsBackFromTodayOrYesterday() {
        assertThat(DashboardService.consecutiveDays(Set.of(TODAY, TODAY.minusDays(1), TODAY.minusDays(3)), TODAY)).isEqualTo(2);
        assertThat(DashboardService.consecutiveDays(Set.of(TODAY.minusDays(1), TODAY.minusDays(2)), TODAY)).isEqualTo(2);
        assertThat(DashboardService.consecutiveDays(Set.of(TODAY.minusDays(2)), TODAY)).isZero();
    }
}
