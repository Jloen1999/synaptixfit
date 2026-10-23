package com.synaptixfit.application.service.admin;

import com.synaptixfit.application.port.input.admin.GetActivityTrendUseCase;
import com.synaptixfit.application.port.input.admin.GetPlatformMetricsUseCase;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation;
import com.synaptixfit.domain.model.admin.DailyActivityPoint;
import com.synaptixfit.domain.model.admin.PlatformMetrics;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.admin.PlatformMetricsQueryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Indicadores globales y tendencia diaria del panel. Los días se cuentan en UTC; el puerto trae filas
 * y {@link AdminActivityAggregation} decide quién está activo cada día.
 */
public class AdminMetricsService implements GetPlatformMetricsUseCase, GetActivityTrendUseCase {

    public static final int MAX_TREND_DAYS = 90;

    private final PlatformMetricsQueryPort metrics;
    private final Clock clock;

    public AdminMetricsService(PlatformMetricsQueryPort metrics, Clock clock) {
        this.metrics = metrics;
        this.clock = clock;
    }

    @Override
    public PlatformMetrics getPlatformMetrics() {
        Instant now = clock.instant();
        LocalDate today = LocalDate.ofInstant(now, ZoneOffset.UTC);
        return PlatformMetrics.of(metrics.counts(now), dailyActivity(today, today).getFirst());
    }

    @Override
    public List<DailyActivityPoint> getActivityTrend(int days) {
        Guard.range(days, "days", 1, MAX_TREND_DAYS);
        LocalDate today = LocalDate.ofInstant(clock.instant(), ZoneOffset.UTC);
        return dailyActivity(today.minusDays(days - 1L), today);
    }

    private List<DailyActivityPoint> dailyActivity(LocalDate from, LocalDate to) {
        Instant fromTs = from.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant toTs = to.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        return AdminActivityAggregation.daily(from, to, metrics.signups(fromTs, toTs),
                metrics.completedTrainingSessions(fromTs, toTs), metrics.completedBlocks(fromTs, toTs),
                metrics.focusSessions(from, to));
    }
}
