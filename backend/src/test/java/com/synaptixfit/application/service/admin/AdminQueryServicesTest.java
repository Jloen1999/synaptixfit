package com.synaptixfit.application.service.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.admin.AdminUserNotFoundException;
import com.synaptixfit.domain.model.admin.AcademicProfileSnapshot;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyInterval;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyWeek;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserActivity;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.AdminUserCounts;
import com.synaptixfit.domain.model.admin.AdminUserStats;
import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.admin.DailyActivityPoint;
import com.synaptixfit.domain.model.admin.PlatformCounts;
import com.synaptixfit.domain.model.admin.PlatformMetrics;
import com.synaptixfit.domain.model.admin.TimelineEntry;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;
import com.synaptixfit.domain.model.admin.WeeklyActivityPoint;
import com.synaptixfit.domain.model.admin.WellbeingProfileSnapshot;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.admin.PlatformMetricsQueryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AdminQueryServicesTest {

    private final List<LocalDate[]> ranges = new ArrayList<>();

    @Test
    void trendCoversTheRequestedDaysEndingTodayInUtcAndCountsActiveUsersOncePerDay() {
        UUID ana = UUID.randomUUID();
        UUID bea = UUID.randomUUID();
        List<Instant[]> instantRanges = new ArrayList<>();
        AdminMetricsService service = new AdminMetricsService(new PlatformMetricsQueryPort() {
            @Override public PlatformCounts counts(Instant now) { return new PlatformCounts(5, 2, 3, 1, 1, 0); }
            @Override public List<Instant> signups(Instant from, Instant to) {
                instantRanges.add(new Instant[]{from, to});
                return List.of(Instant.parse("2026-10-14T08:00:00Z"));
            }
            // Ana entrena y estudia hoy (cuenta una vez); Bea solo hace un Pomodoro.
            @Override public List<UserActivity> completedTrainingSessions(Instant from, Instant to) {
                return List.of(new UserActivity(ana, Instant.parse("2026-10-14T09:00:00Z")));
            }
            @Override public List<UserActivity> completedBlocks(Instant from, Instant to) {
                return List.of(new UserActivity(ana, Instant.parse("2026-10-14T11:00:00Z")));
            }
            @Override public List<UserFocus> focusSessions(LocalDate from, LocalDate to) {
                ranges.add(new LocalDate[]{from, to});
                return List.of(new UserFocus(bea, LocalDate.of(2026, 10, 14), 25));
            }
        }, AdminTestFixtures.CLOCK);

        List<DailyActivityPoint> trend = service.getActivityTrend(30);

        assertThat(ranges.get(0)[0]).isEqualTo(LocalDate.of(2026, 9, 15));
        assertThat(ranges.get(0)[1]).isEqualTo(LocalDate.of(2026, 10, 14));
        assertThat(instantRanges.get(0)[0]).isEqualTo(Instant.parse("2026-09-15T00:00:00Z"));
        assertThat(instantRanges.get(0)[1]).isEqualTo(Instant.parse("2026-10-15T00:00:00Z"));
        assertThat(trend).hasSize(30).last()
                .isEqualTo(new DailyActivityPoint(LocalDate.of(2026, 10, 14), 1, 2, 1));
        PlatformMetrics metrics = service.getPlatformMetrics();
        assertThat(metrics.activeUsersToday()).isEqualTo(2);
        assertThat(metrics.pendingReportedContent()).isEqualTo(2);
        assertThat(metrics.newUsersToday()).isEqualTo(1);
        assertThatThrownBy(() -> service.getActivityTrend(0)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> service.getActivityTrend(91)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void weeklyActivityStartsOnMondaysAndRequiresAnExistingUser() {
        AdminTestFixtures.InMemoryUsers users = new AdminTestFixtures.InMemoryUsers();
        User user = users.add(AdminTestFixtures.user("someone@example.com", Role.USER));
        AdminUserQueryService service = new AdminUserQueryService(users, new StubQueries(), AdminTestFixtures.CLOCK);

        List<WeeklyActivityPoint> weeks = service.getUserWeeklyActivity(user.id(), 4);

        // 2026-10-14 es miércoles: la semana actual empieza el lunes 12; el rango de días acaba el 19 (excluido).
        assertThat(ranges.get(0)[0]).isEqualTo(LocalDate.of(2026, 9, 21));
        assertThat(ranges.get(0)[1]).isEqualTo(LocalDate.of(2026, 10, 19));
        assertThat(weeks).hasSize(4);
        WeeklyActivityPoint current = weeks.get(3);
        assertThat(current.weekStart()).isEqualTo(LocalDate.of(2026, 10, 12));
        assertThat(current.trainingSessions()).isEqualTo(1);
        assertThat(current.studyMinutes()).isEqualTo(90);
        assertThat(current.focusMinutes()).isEqualTo(25);
        assertThatThrownBy(() -> service.getUserStats(UUID.randomUUID()))
                .isInstanceOf(AdminUserNotFoundException.class);
        assertThatThrownBy(() -> service.getUserWeeklyActivity(user.id(), 53))
                .isInstanceOf(FieldValidationException.class);
        assertThat(service.getUserDetail(user.id()).wellbeing()).isNull();
    }

    @Test
    void statsAddStudyMinutesAndAdherenceToTheCounts() {
        AdminTestFixtures.InMemoryUsers users = new AdminTestFixtures.InMemoryUsers();
        User user = users.add(AdminTestFixtures.user("stats@example.com", Role.USER));
        AdminUserQueryService service = new AdminUserQueryService(users, new StubQueries(), AdminTestFixtures.CLOCK);

        AdminUserStats stats = service.getUserStats(user.id());

        assertThat(stats.trainingSessions()).isEqualTo(3);
        assertThat(stats.studyMinutes()).isEqualTo(90);
        // (6 + 3) / (10 + 10) horas = 45 % de las semanas registradas.
        assertThat(stats.academicAdherencePercent()).isEqualTo(45);
        assertThat(stats.adherenceWeeks()).isEqualTo(2);
    }

    private final class StubQueries implements AdminUserQueryPort {
        private final Instant monday = Instant.parse("2026-10-12T09:00:00Z");

        @Override public PageResult<AdminUserSummary> search(UserSearchCriteria c, PageRequest p) {
            return new PageResult<>(List.of(), 0, 20, 0);
        }
        @Override public Optional<WellbeingProfileSnapshot> findWellbeingProfile(UUID userId) { return Optional.empty(); }
        @Override public Optional<AcademicProfileSnapshot> findAcademicProfile(UUID userId) { return Optional.empty(); }
        @Override public AdminUserCounts counts(UUID userId) {
            return new AdminUserCounts(3, 90, 500, 6.5, 1, 1, 2, 1, 0, 2, 0, 0, 1, 1, 25, 0, 0, 0, 0, 0, null);
        }
        @Override public List<StudyWeek> recentStudyWeeks(UUID userId, int weeks) {
            assertThat(weeks).isEqualTo(AdminActivityAggregation.ADHERENCE_WEEKS);
            return List.of(new StudyWeek(10, 6), new StudyWeek(10, 3));
        }
        @Override public List<StudyInterval> completedStudyIntervals(UUID userId, Instant from, Instant to) {
            return List.of(new StudyInterval(monday, monday.plusSeconds(5400)));
        }
        @Override public List<CompletedSession> completedTrainingSessions(UUID userId, Instant from, Instant to) {
            assertThat(from).isEqualTo(Instant.parse("2026-09-21T00:00:00Z"));
            assertThat(to).isEqualTo(Instant.parse("2026-10-19T00:00:00Z"));
            return List.of(new CompletedSession(monday, 45, 300.0, 7));
        }
        @Override public List<UserFocus> completedFocus(UUID userId, LocalDate from, LocalDate to) {
            ranges.add(new LocalDate[]{from, to});
            return List.of(new UserFocus(userId, LocalDate.of(2026, 10, 13), 25));
        }
        @Override public PageResult<TimelineEntry> timeline(UUID userId, PageRequest page) {
            return new PageResult<>(List.of(), 0, 20, 0);
        }
        @Override public long countActiveAdmins() { return 1; }
    }
}
