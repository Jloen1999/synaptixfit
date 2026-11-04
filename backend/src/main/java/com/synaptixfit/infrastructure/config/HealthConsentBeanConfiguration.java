package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.GetHealthConsentUseCase;
import com.synaptixfit.application.port.input.training.GiveHealthConsentUseCase;
import com.synaptixfit.application.port.input.training.WithdrawHealthConsentUseCase;
import com.synaptixfit.application.service.training.HealthConsentService;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.HealthConsentRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición del consentimiento para el registro diario (ADR 0034). */
@Configuration
public class HealthConsentBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final HealthConsentRepositoryPort consents;
    private final DailyCheckInRepositoryPort checkIns;
    private final Clock clock;
    private final ZoneId zone;

    public HealthConsentBeanConfiguration(TransactionalUseCaseFactory tx, HealthConsentRepositoryPort consents,
                                          DailyCheckInRepositoryPort checkIns, Clock clock,
                                          @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.consents = consents;
        this.checkIns = checkIns;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @Bean(autowireCandidate = false)
    HealthConsentService healthConsentService() {
        return new HealthConsentService(consents, checkIns, clock, zone);
    }

    @Bean
    GetHealthConsentUseCase getHealthConsentUseCase() {
        return tx.wrap(GetHealthConsentUseCase.class, healthConsentService());
    }

    @Bean
    GiveHealthConsentUseCase giveHealthConsentUseCase() {
        return tx.wrap(GiveHealthConsentUseCase.class, healthConsentService());
    }

    @Bean
    WithdrawHealthConsentUseCase withdrawHealthConsentUseCase() {
        return tx.wrap(WithdrawHealthConsentUseCase.class, healthConsentService());
    }
}
