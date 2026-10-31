package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.service.planner.PastActivityService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de «Apuntar una actividad pasada» (planificador). */
@Configuration
public class PastActivityBeanConfiguration {

    @Bean
    LogPastActivityUseCase logPastActivityUseCase(TransactionalUseCaseFactory tx, CalendarBlockRepositoryPort blocks,
                                                  SetBlockCompletionUseCase completion,
                                                  @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId,
                                                  Clock clock) {
        return tx.wrap(LogPastActivityUseCase.class,
                new PastActivityService(blocks, completion, PlannerZone.of(zoneId), clock));
    }
}
