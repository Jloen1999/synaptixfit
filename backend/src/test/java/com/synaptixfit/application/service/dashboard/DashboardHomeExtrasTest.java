package com.synaptixfit.application.service.dashboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyActivityUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.application.port.input.social.ListFriendshipsUseCase;
import com.synaptixfit.application.port.input.training.ListOpenSessionsUseCase;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import com.synaptixfit.domain.model.dashboard.SmartBanner;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.PhysicalLoadSummary;
import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.domain.model.training.OpenTrainingSession;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.SessionType;
import com.synaptixfit.domain.model.training.TrainingSession;
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
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Lo que Inicio añade en el ADR 0059: sesión a medias, lo de ayer sin marcar, aula, solicitudes y la semana. */
class DashboardHomeExtrasTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-19T12:00:00Z"); // miércoles
    private static final LocalDate TODAY = LocalDate.of(2026, 11, 19);

    private final UserRepositoryPort users = mock(UserRepositoryPort.class);
    private final DashboardReadPort reads = mock(DashboardReadPort.class);
    private final InsightsSourcePort sources = mock(InsightsSourcePort.class);
    private final GetCrossRegulationUseCase regulation = mock(GetCrossRegulationUseCase.class);
    private List<OpenTrainingSession> open = List.of();
    private long requests;
    private DashboardService service;

    @BeforeEach
    void setUp() {
        GetCognitiveStateUseCase cognitive = (u, tz) -> CognitiveState.initial(u, NOW);
        GetStudyCaloriesTodayUseCase calories = (u, tz) -> new StudyCaloriesSummary(TODAY, 0, 0, 0);
        GetPhysicalLoadUseCase load = (u, tz) -> new PhysicalLoadSummary(TODAY, 0, 0, 0, List.of());
        GetWellbeingUseCase wellbeing = (u, tz) -> new WellbeingSnapshot(TODAY, false, null, null, null, null, null);
        CrossRegulationState optimal = CrossRegulationState.compute(USER, 2100, 8400, null, NOW);
        when(regulation.getCrossRegulation(eq(USER), any()))
                .thenReturn(new CrossRegulationView(optimal, optimal.acwr(), optimal.zone(), 0, 1.0));
        when(users.findById(USER)).thenReturn(Optional.of(User.builder().id(USER).email("a@b.com").fullName("Ana")
                .level(1).levelXp(0).streak(0).privacy(Visibility.PRIVATE).role(Role.USER).passwordHash("x")
                .createdAt(NOW).build()));
        when(reads.trainingTotals(eq(USER), any(), any())).thenReturn(new TrainingTotals(0, 0, 0));
        when(reads.plannedWeeklySessions(eq(USER), any())).thenReturn(Optional.empty());
        when(reads.lastTrainingSession(USER)).thenReturn(Optional.empty());
        when(reads.deadlines(eq(USER), any(), any())).thenReturn(List.of());
        when(sources.checkIns(eq(USER), any(), any())).thenReturn(List.of());
        when(sources.completedStudyBlocks(eq(USER), any(), any())).thenReturn(List.of());
        ListMyChallengesUseCase challenges = (u, q, page) -> new PageResult<>(List.of(), 0, page.size(), 0);
        GetStudyActivityUseCase studyActivity = (u, from, to) -> List.of();
        ListOpenSessionsUseCase openSessions = u -> open;
        ListFriendshipsUseCase friendships = (u, kind, page) -> {
            assertThat(kind).isEqualTo(FriendshipListKind.RECEIVED);
            return new PageResult<>(List.of(), 0, page.size(), requests);
        };
        service = new DashboardService(users, reads, sources, cognitive, regulation, calories, studyActivity, load,
                wellbeing, challenges, u -> Optional.empty(), null, null, openSessions, friendships,
                Clock.fixed(NOW, ZoneOffset.UTC), ZoneId.of("UTC"));
    }

    @Test
    void theUnfinishedSessionIsTheLeftoverOneWithItsExercises() {
        when(reads.calendarBlocks(eq(USER), any(), any())).thenReturn(List.of());
        UUID planned = UUID.randomUUID();
        TrainingSession yesterday = new TrainingSession(UUID.randomUUID(), USER, UUID.randomUUID(), UUID.randomUUID(),
                SessionType.ROUTINE, Instant.parse("2026-11-18T18:10:00Z"), null, 0, null, null, 0,
                List.of(new SessionSet(UUID.randomUUID(), planned, 1, 10, 50.0, true, 0, null, null, null, null)));
        TrainingSession now = TrainingSession.start(USER, null, null, NOW.minusSeconds(600));
        open = List.of(new OpenTrainingSession(now, null, false), new OpenTrainingSession(yesterday,
                new SessionLabel(yesterday.id(), "Fuerza 3 días", "Pierna y empuje", 1, 1).withExerciseCount(6),
                true));

        Dashboard.UnfinishedSession u = service.getDashboard(USER, "UTC").extras().unfinishedSession();

        assertThat(u.sessionId()).isEqualTo(yesterday.id());
        assertThat(u.dayName()).isEqualTo("Pierna y empuje");
        assertThat(u.exercisesDone()).isEqualTo(1);
        assertThat(u.exercisesTotal()).isEqualTo(6);
        assertThat(u.startedAt()).isEqualTo(Instant.parse("2026-11-18T18:10:00Z"));
    }

    @Test
    void aSessionStartedTodayIsNotUnfinished() {
        when(reads.calendarBlocks(eq(USER), any(), any())).thenReturn(List.of());
        open = List.of(new OpenTrainingSession(TrainingSession.start(USER, null, null, NOW.minusSeconds(600)), null,
                false));
        assertThat(service.getDashboard(USER, "UTC").extras().unfinishedSession()).isNull();
    }

    @Test
    void yesterdaysMissedEventsComeNamedAndTodaysClassSaysWhereAndWho() {
        Instant yesterdayStudy = Instant.parse("2026-11-18T19:00:00Z");
        Instant yesterdayGym = Instant.parse("2026-11-18T08:00:00Z");
        Instant lecture = Instant.parse("2026-11-19T11:30:00Z");
        CalendarBlock study = new CalendarBlock(UUID.randomUUID(), "estudio", yesterdayStudy,
                yesterdayStudy.plusSeconds(3600), false, "Cálculo", null);
        CalendarBlock sport = new CalendarBlock(UUID.randomUUID(), "deporte", yesterdayGym,
                yesterdayGym.plusSeconds(3600), false, null, "Correr");
        CalendarBlock lesson = new CalendarBlock(UUID.randomUUID(), "clase", lecture, lecture.plusSeconds(3600), false,
                "Bases de datos", null, null, null, null, null, "Aula 2.4", "Ana Ruiz");
        when(reads.calendarBlocks(eq(USER), any(), any())).thenReturn(List.of(sport, study, lesson));
        requests = 2;

        Dashboard d = service.getDashboard(USER, "UTC");

        assertThat(d.extras().missedEvents()).extracting(Dashboard.TodayEvent::id)
                .containsExactly(study.id(), sport.id());
        assertThat(d.extras().missedEvents().getFirst().title()).isEqualTo("Cálculo");
        // Lo dice su tarjeta, evento a evento: el aviso de Inicio deja sitio a otro.
        assertThat(d.banner().type()).isNotEqualTo(SmartBanner.Type.MISSED_BLOCKS);
        assertThat(d.todayEvents()).singleElement().satisfies(e -> {
            assertThat(e.place()).isEqualTo("Aula 2.4");
            assertThat(e.teacher()).isEqualTo("Ana Ruiz");
        });
        assertThat(d.spotlightEventId()).isEqualTo(lesson.id());
        assertThat(d.extras().pendingFriendRequests()).isEqualTo(2);
        // Una hora de estudio planificada esta semana (la clase no cuenta como estudio).
        assertThat(d.extras().studyMinutesPlannedWeek()).isEqualTo(60);
    }
}
