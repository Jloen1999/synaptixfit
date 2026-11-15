package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.CopySharedRoutineUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineShareLinkUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineShareLinkStatusUseCase;
import com.synaptixfit.application.port.input.training.PreviewSharedRoutineUseCase;
import com.synaptixfit.application.port.input.training.RevokeRoutineShareLinksUseCase;
import com.synaptixfit.application.service.training.RoutineShareLinkService;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineShareLinkRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de compartir una rutina por enlace (ADR 0043). */
@Configuration
public class RoutineShareLinkBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final RoutineRepositoryPort routines;
    private final RoutineShareLinkRepositoryPort links;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    public RoutineShareLinkBeanConfiguration(TransactionalUseCaseFactory tx, RoutineRepositoryPort routines,
                                             RoutineShareLinkRepositoryPort links, DomainEventPublisherPort events,
                                             Clock clock) {
        this.tx = tx;
        this.routines = routines;
        this.links = links;
        this.events = events;
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    RoutineShareLinkService routineShareLinkService() {
        return new RoutineShareLinkService(routines, links, events, clock);
    }

    @Bean
    CreateRoutineShareLinkUseCase createRoutineShareLinkUseCase() {
        return tx.wrap(CreateRoutineShareLinkUseCase.class, routineShareLinkService());
    }

    @Bean
    RevokeRoutineShareLinksUseCase revokeRoutineShareLinksUseCase() {
        return tx.wrap(RevokeRoutineShareLinksUseCase.class, routineShareLinkService());
    }

    @Bean
    GetRoutineShareLinkStatusUseCase getRoutineShareLinkStatusUseCase() {
        return tx.wrap(GetRoutineShareLinkStatusUseCase.class, routineShareLinkService());
    }

    @Bean
    PreviewSharedRoutineUseCase previewSharedRoutineUseCase() {
        return tx.wrap(PreviewSharedRoutineUseCase.class, routineShareLinkService());
    }

    @Bean
    CopySharedRoutineUseCase copySharedRoutineUseCase() {
        return tx.wrap(CopySharedRoutineUseCase.class, routineShareLinkService());
    }
}
