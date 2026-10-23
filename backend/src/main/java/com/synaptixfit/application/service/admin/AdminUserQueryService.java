package com.synaptixfit.application.service.admin;

import com.synaptixfit.application.port.input.admin.GetUserDetailUseCase;
import com.synaptixfit.application.port.input.admin.GetUserStatsUseCase;
import com.synaptixfit.application.port.input.admin.GetUserTimelineUseCase;
import com.synaptixfit.application.port.input.admin.GetUserWeeklyActivityUseCase;
import com.synaptixfit.application.port.input.admin.SearchUsersUseCase;
import com.synaptixfit.domain.exception.admin.AdminUserNotFoundException;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation;
import com.synaptixfit.domain.model.admin.AdminUserDetail;
import com.synaptixfit.domain.model.admin.AdminUserStats;
import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.admin.TimelineEntry;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;
import com.synaptixfit.domain.model.admin.WeeklyActivityPoint;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.UUID;

/** Consultas del panel sobre usuarios: listado, ficha, estadísticas, gráficos y línea de tiempo. */
public class AdminUserQueryService implements SearchUsersUseCase, GetUserDetailUseCase, GetUserStatsUseCase,
        GetUserWeeklyActivityUseCase, GetUserTimelineUseCase {

    public static final int MAX_WEEKS = 52;

    private final UserRepositoryPort users;
    private final AdminUserQueryPort queries;
    private final Clock clock;

    public AdminUserQueryService(UserRepositoryPort users, AdminUserQueryPort queries, Clock clock) {
        this.users = users;
        this.queries = queries;
        this.clock = clock;
    }

    @Override
    public PageResult<AdminUserSummary> searchUsers(UserSearchCriteria criteria, PageRequest page) {
        return queries.search(criteria, page);
    }

    @Override
    public AdminUserDetail getUserDetail(UUID userId) {
        User user = existing(userId);
        return new AdminUserDetail(user, queries.findWellbeingProfile(userId).orElse(null),
                queries.findAcademicProfile(userId).orElse(null));
    }

    @Override
    public AdminUserStats getUserStats(UUID userId) {
        existing(userId);
        return AdminUserStats.of(queries.counts(userId), queries.completedStudyIntervals(userId, null, null),
                queries.recentStudyWeeks(userId, AdminActivityAggregation.ADHERENCE_WEEKS));
    }

    /** Un punto por semana (lunes, en UTC como el resto del panel), también las semanas vacías. */
    @Override
    public List<WeeklyActivityPoint> getUserWeeklyActivity(UUID userId, int weeks) {
        Guard.range(weeks, "weeks", 1, MAX_WEEKS);
        existing(userId);
        LocalDate lastWeek = LocalDate.ofInstant(clock.instant(), ZoneOffset.UTC)
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate firstWeek = lastWeek.minusWeeks(weeks - 1L);
        LocalDate endDay = lastWeek.plusDays(7);
        Instant from = firstWeek.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant to = endDay.atStartOfDay(ZoneOffset.UTC).toInstant();
        return AdminActivityAggregation.weekly(firstWeek, lastWeek, queries.completedTrainingSessions(userId, from, to),
                queries.completedStudyIntervals(userId, from, to), queries.completedFocus(userId, firstWeek, endDay));
    }

    @Override
    public PageResult<TimelineEntry> getUserTimeline(UUID userId, PageRequest page) {
        existing(userId);
        return queries.timeline(userId, page);
    }

    private User existing(UUID userId) {
        return users.findById(userId).orElseThrow(() -> new AdminUserNotFoundException(userId));
    }
}
