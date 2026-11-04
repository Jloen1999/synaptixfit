package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.challenge.ListRoutineDayLinkTargetsUseCase;
import com.synaptixfit.application.service.challenge.RoutineDayLinkTargetService;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de los días de rutina vinculables a tareas de reto (ADR 0032). */
@Configuration
public class ChallengeLinkTargetBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final ChallengeReferencePort references;

    public ChallengeLinkTargetBeanConfiguration(TransactionalUseCaseFactory tx, ChallengeReferencePort references) {
        this.tx = tx;
        this.references = references;
    }

    @Bean
    ListRoutineDayLinkTargetsUseCase listRoutineDayLinkTargetsUseCase() {
        return tx.wrap(ListRoutineDayLinkTargetsUseCase.class, new RoutineDayLinkTargetService(references));
    }
}
