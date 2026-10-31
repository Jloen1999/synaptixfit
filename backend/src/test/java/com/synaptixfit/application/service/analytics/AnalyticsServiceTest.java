package com.synaptixfit.application.service.analytics;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.analytics.InvalidCorrelationMetricException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.analytics.Insight;
import com.synaptixfit.domain.model.analytics.LoadCorrelation;
import com.synaptixfit.domain.model.analytics.StudyWeekSummary;
import com.synaptixfit.domain.model.analytics.WeeklyAnalytics;
import com.synaptixfit.domain.model.analytics.WeeklyStudyLoad;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.analytics.AnalyticsSourcePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

class AnalyticsServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-18T10:00:00Z"); // domingo
    private static final LocalDate CURRENT_WEEK = LocalDate.of(2026, 10, 12);

    /** Sesiones guardadas (filas): el servicio las agrupa por semana. */
    private final List<CompletedSession> training = new ArrayList<>();
    private final List<WeeklyStudyLoad> study = new ArrayList<>();
    private final List<Instant> requestedFrom = new ArrayList<>();
    private final List<Instant> studyRequest = new ArrayList<>();
    private final List<String> studyCodes = new ArrayList<>();
    private UserRepositoryPort users;
    private AnalyticsService service;

    @BeforeEach
    void setUp() {
        users = Mockito.mock(UserRepositoryPort.class);
        service = new AnalyticsService(sourcesDouble(), users, Clock.fixed(NOW, ZoneOffset.UTC), ZoneId.of("UTC"));
    }

    private AnalyticsSourcePort sourcesDouble() {
        return new AnalyticsSourcePort() {
            public List<CompletedSession> completedTrainingSessions(UUID userId, Instant from) {
                requestedFrom.add(from);
                return training.stream().filter(t -> !t.completedAt().isBefore(from)).toList();
            }

            public List<WeeklyStudyLoad> weeklyStudyLoads(UUID userId, LocalDate fromWeek) {
                return study.stream().filter(s -> !s.weekStart().isBefore(fromWeek)).toList();
            }

            public StudyWeekSummary.Counts studyCounts(UUID userId, Instant from, Instant to, LocalDate fromDay,
                                                       LocalDate toDay, List<String> codes, Instant now) {
                studyRequest.addAll(List.of(from, to));
                studyCodes.addAll(codes);
                return new StudyWeekSummary.Counts(150, 3, 8, 6, 12, 2, 15, 20, 4, 9, 12);
            }
        };
    }

    @Test
    void weeklyAnalyticsCoversThePeriodEndingThisWeek() {
        sessions(CURRENT_WEEK, 3, 7, 50, 300.0);
        WeeklyAnalytics a = service.getWeeklyAnalytics(USER, "WEEKLY");
        assertThat(a.fromWeek()).isEqualTo(CURRENT_WEEK.minusWeeks(3));
        assertThat(a.toWeek()).isEqualTo(CURRENT_WEEK);
        assertThat(a.weeks()).hasSize(4);
        assertThat(a.weeks()).last().isEqualTo(new WeeklyTrainingMetric(CURRENT_WEEK, 3, 7.0, 150, 900));
        assertThat(requestedFrom).containsExactly(Instant.parse("2026-09-21T00:00:00Z"));
        assertThat(service.getWeeklyAnalytics(USER, null).weeks()).hasSize(12);
    }

    @Test
    void weeksAreThoseOfTheAppTimeZone() {
        // Lunes 00:30 en Madrid es aún domingo en UTC: la sesión es de la semana actual, no de la anterior.
        AnalyticsService madrid = new AnalyticsService(sourcesDouble(), users, Clock.fixed(NOW, ZoneOffset.UTC),
                ZoneId.of("Europe/Madrid"));
        training.add(new CompletedSession(Instant.parse("2026-10-11T22:30:00Z"), 30, null, 6));

        WeeklyAnalytics a = madrid.getWeeklyAnalytics(USER, "WEEKLY");

        assertThat(a.weeks()).filteredOn(w -> w.sessions() > 0).singleElement()
                .satisfies(w -> assertThat(w.weekStart()).isEqualTo(CURRENT_WEEK));
        assertThat(requestedFrom).containsExactly(Instant.parse("2026-09-20T22:00:00Z"));
    }

    @Test
    void correlationUsesTheLastYear() {
        for (int i = 0; i < 6; i++) {
            LocalDate w = CURRENT_WEEK.minusWeeks(i);
            study.add(new WeeklyStudyLoad(w, 10 + i * 5));
            sessions(w, 2, 9 - i, 30 + i * 5, 200.0);
        }
        LoadCorrelation rpe = service.getLoadCorrelation(USER, null);
        assertThat(rpe.coefficient()).isCloseTo(-1.0, org.assertj.core.api.Assertions.within(1e-9));
        LoadCorrelation minutes = service.getLoadCorrelation(USER, "minutes");
        assertThat(minutes.coefficient()).isCloseTo(1.0, org.assertj.core.api.Assertions.within(1e-9));
        assertThatThrownBy(() -> service.getLoadCorrelation(USER, "calories"))
                .isInstanceOf(InvalidCorrelationMetricException.class);
    }

    @Test
    void insightsIncludeStreakConsistencyVolumeAndCorrelationWhenAvailable() {
        Mockito.when(users.findById(USER)).thenReturn(Optional.of(user(8)));
        sessions(CURRENT_WEEK, 2, 6, 60, null);
        sessions(CURRENT_WEEK.minusWeeks(1), 2, 6, 60, null);

        List<Insight> insights = service.getAnalyticsInsights(USER, "WEEKLY");

        assertThat(insights).extracting(Insight::type)
                .containsExactly(Insight.Type.STREAK, Insight.Type.CONSISTENCY, Insight.Type.VOLUME);
        assertThat(insights.get(0).params()).containsEntry("days", 8);
        assertThat(insights.get(1).params()).containsEntry("weeks", 2);
        assertThat(insights.get(2).params()).containsEntry("totalMinutes", 240);
    }

    @Test
    void insightsOfUnknownUserAreNotFound() {
        Mockito.when(users.findById(USER)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.getAnalyticsInsights(USER, null)).isInstanceOf(UserNotFoundException.class);
    }

    /** {@code count} sesiones el lunes {@code week} a las 10:00 UTC. */
    private void sessions(LocalDate week, int count, int rpe, int minutes, Double calories) {
        for (int i = 0; i < count; i++) {
            training.add(new CompletedSession(week.atTime(10, i).toInstant(ZoneOffset.UTC), minutes, calories, rpe));
        }
    }

    static User user(int streak) {
        return User.builder().id(USER).email("a@b.com").fullName("Ana").level(2).levelXp(10).streak(streak)
                .privacy(Visibility.PRIVATE).role(Role.USER).passwordHash("x").createdAt(NOW).build();
    }

    @Test
    void studyWeekCountsTheCurrentWeekWithStudyAndReviewBlocks() {
        StudyWeekSummary summary = service.getStudyWeekSummary(USER);

        assertThat(summary.weekStart()).isEqualTo(CURRENT_WEEK);
        assertThat(studyRequest).containsExactly(Instant.parse("2026-10-12T00:00:00Z"),
                Instant.parse("2026-10-19T00:00:00Z"));
        assertThat(studyCodes).containsExactlyInAnyOrder("estudio", "repaso");
        assertThat(summary.focusMinutes()).isEqualTo(150);
        assertThat(summary.planAdherence()).isEqualTo(75);
        assertThat(summary.averageTestScore()).isEqualTo(75);
        assertThat(summary.reviewsDue()).isEqualTo(4);
        assertThat(summary.studyHours()).isEqualTo(9);
        assertThat(summary.weeklyGoalHours()).isEqualTo(12);
        assertThat(summary.isEmpty()).isFalse();
    }

    @Test
    void withoutPlannedBlocksOrTestsThereIsNoPercentage() {
        StudyWeekSummary empty = StudyWeekSummary.of(CURRENT_WEEK,
                new StudyWeekSummary.Counts(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, null));

        assertThat(empty.planAdherence()).isNull();
        // Sin perfil académico el objetivo es el de por defecto (el mismo que el del bonus semanal).
        assertThat(empty.weeklyGoalHours()).isEqualTo(PlannerProfile.Academic.DEFAULT_WEEKLY_GOAL_HOURS);
        assertThat(empty.averageTestScore()).isNull();
        assertThat(empty.isEmpty()).isTrue();
    }
}
