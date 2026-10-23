package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.analytics.GetAnalyticsInsightsUseCase;
import com.synaptixfit.application.port.input.analytics.GetLoadCorrelationUseCase;
import com.synaptixfit.application.port.input.analytics.GetRpeTrendUseCase;
import com.synaptixfit.application.port.input.analytics.GetStudyWeekSummaryUseCase;
import com.synaptixfit.application.port.input.analytics.GetTrainingVolumeUseCase;
import com.synaptixfit.application.port.input.analytics.GetWeeklyAnalyticsUseCase;
import com.synaptixfit.application.service.analytics.AnalyticsService;
import com.synaptixfit.domain.port.output.analytics.AnalyticsSourcePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de la analítica de entrenamiento. */
@Configuration
public class AnalyticsBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final AnalyticsSourcePort sources;
    private final UserRepositoryPort users;
    private final Clock clock;
    private final ZoneId zone;

    public AnalyticsBeanConfiguration(TransactionalUseCaseFactory tx, AnalyticsSourcePort sources,
                                      UserRepositoryPort users, Clock clock,
                                      @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.sources = sources;
        this.users = users;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @Bean(autowireCandidate = false)
    AnalyticsService analyticsService() {
        return new AnalyticsService(sources, users, clock, zone);
    }

    @Bean
    GetWeeklyAnalyticsUseCase getWeeklyAnalyticsUseCase() {
        return tx.wrap(GetWeeklyAnalyticsUseCase.class, analyticsService());
    }

    @Bean
    GetRpeTrendUseCase getRpeTrendUseCase() {
        return tx.wrap(GetRpeTrendUseCase.class, analyticsService());
    }

    @Bean
    GetTrainingVolumeUseCase getTrainingVolumeUseCase() {
        return tx.wrap(GetTrainingVolumeUseCase.class, analyticsService());
    }

    @Bean
    GetLoadCorrelationUseCase getLoadCorrelationUseCase() {
        return tx.wrap(GetLoadCorrelationUseCase.class, analyticsService());
    }

    @Bean
    GetAnalyticsInsightsUseCase getAnalyticsInsightsUseCase() {
        return tx.wrap(GetAnalyticsInsightsUseCase.class, analyticsService());
    }

    @Bean
    GetStudyWeekSummaryUseCase getStudyWeekSummaryUseCase() {
        return tx.wrap(GetStudyWeekSummaryUseCase.class, analyticsService());
    }
}
