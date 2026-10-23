package com.synaptixfit.application.service.analytics;

import com.synaptixfit.application.port.input.analytics.GetAnalyticsInsightsUseCase;
import com.synaptixfit.application.port.input.analytics.GetLoadCorrelationUseCase;
import com.synaptixfit.application.port.input.analytics.GetRpeTrendUseCase;
import com.synaptixfit.application.port.input.analytics.GetStudyWeekSummaryUseCase;
import com.synaptixfit.application.port.input.analytics.GetTrainingVolumeUseCase;
import com.synaptixfit.application.port.input.analytics.GetWeeklyAnalyticsUseCase;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.analytics.AnalyticsPeriod;
import com.synaptixfit.domain.model.analytics.CorrelationMetric;
import com.synaptixfit.domain.model.analytics.Insight;
import com.synaptixfit.domain.model.analytics.InsightGenerator;
import com.synaptixfit.domain.model.analytics.LoadCorrelation;
import com.synaptixfit.domain.model.analytics.RpeTrend;
import com.synaptixfit.domain.model.analytics.StudyWeekSummary;
import com.synaptixfit.domain.model.analytics.TrainingVolume;
import com.synaptixfit.domain.model.analytics.WeeklyAnalytics;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.analytics.AnalyticsSourcePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

/**
 * Analítica de entrenamiento y su relación con la carga académica (antes {@code analitica_repository.dart}).
 * Agrupa por semanas (de lunes, en la zona de la app) las sesiones que trae {@link AnalyticsSourcePort}.
 */
public class AnalyticsService implements GetWeeklyAnalyticsUseCase, GetRpeTrendUseCase, GetTrainingVolumeUseCase,
        GetLoadCorrelationUseCase, GetAnalyticsInsightsUseCase, GetStudyWeekSummaryUseCase {

    /** Historial usado para la correlación (un año). */
    static final int CORRELATION_WEEKS = 52;

    private final AnalyticsSourcePort sources;
    private final UserRepositoryPort users;
    private final Clock clock;
    private final ZoneId zone;

    public AnalyticsService(AnalyticsSourcePort sources, UserRepositoryPort users, Clock clock, ZoneId zone) {
        this.sources = sources;
        this.users = users;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public WeeklyAnalytics getWeeklyAnalytics(UUID userId, String period) {
        return weekly(userId, AnalyticsPeriod.parse(period));
    }

    @Override
    public RpeTrend getRpeTrend(UUID userId, String period) {
        return RpeTrend.of(weekly(userId, AnalyticsPeriod.parse(period)));
    }

    @Override
    public TrainingVolume getTrainingVolume(UUID userId, String period) {
        return TrainingVolume.of(weekly(userId, AnalyticsPeriod.parse(period)));
    }

    @Override
    public LoadCorrelation getLoadCorrelation(UUID userId, String metric) {
        return correlation(userId, CorrelationMetric.parse(metric));
    }

    @Override
    public List<Insight> getAnalyticsInsights(UUID userId, String period) {
        AnalyticsPeriod p = AnalyticsPeriod.parse(period);
        User user = users.findById(userId).filter(User::isActive).orElseThrow(() -> new UserNotFoundException(userId));
        return InsightGenerator.generate(user.streak(), weekly(userId, p), correlation(userId, CorrelationMetric.RPE));
    }

    /** Semana en curso (de lunes) en la zona de la app; cuentan como estudio los bloques de estudio y repaso. */
    @Override
    public StudyWeekSummary getStudyWeekSummary(UUID userId) {
        LocalDate week = currentWeek();
        LocalDate next = week.plusWeeks(1);
        return StudyWeekSummary.of(week, sources.studyCounts(userId, TimeZones.startOfDay(week, zone),
                TimeZones.startOfDay(next, zone), week, next, ActivityType.codesWhere(ActivityType::countsAsStudy),
                clock.instant()));
    }

    private WeeklyAnalytics weekly(UUID userId, AnalyticsPeriod period) {
        LocalDate currentWeek = currentWeek();
        return WeeklyAnalytics.of(period, currentWeek,
                weeklyTraining(userId, WeeklyAnalytics.fromWeek(period, currentWeek)));
    }

    private LoadCorrelation correlation(UUID userId, CorrelationMetric metric) {
        LocalDate from = currentWeek().minusWeeks(CORRELATION_WEEKS - 1L);
        return LoadCorrelation.compute(metric, sources.weeklyStudyLoads(userId, from), weeklyTraining(userId, from));
    }

    /** Semanas con entrenamiento desde {@code fromWeek}; las semanas son las del usuario, no las de UTC. */
    private List<WeeklyTrainingMetric> weeklyTraining(UUID userId, LocalDate fromWeek) {
        return WeeklyTrainingMetric.byWeek(
                sources.completedTrainingSessions(userId, TimeZones.startOfDay(fromWeek, zone)), zone);
    }

    private LocalDate currentWeek() {
        return TimeZones.weekStart(LocalDate.ofInstant(clock.instant(), zone));
    }
}
