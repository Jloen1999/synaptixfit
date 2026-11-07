package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.planner.CompletePlannedActivityUseCase;
import com.synaptixfit.application.port.input.planner.ListSportActivitiesUseCase;
import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.service.planner.PastActivityService;
import com.synaptixfit.application.service.planner.SportActivityHistoryService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de «Apuntar una actividad pasada», de dejar hecho un evento como actividad (la carrera grabada desde su
 * entreno, ADR 0037) y del deporte hecho para el historial (planificador).
 */
@Configuration
public class PastActivityBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final SetBlockCompletionUseCase completion;
    private final LoggedActivityRepositoryPort logged;
    private final DomainEventPublisherPort events;
    private final PlannerZone zone;
    private final Clock clock;

    public PastActivityBeanConfiguration(TransactionalUseCaseFactory tx, CalendarBlockRepositoryPort blocks,
                                         SubjectDirectoryPort subjects, SetBlockCompletionUseCase completion,
                                         LoggedActivityRepositoryPort logged, DomainEventPublisherPort events,
                                         @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId,
                                         Clock clock) {
        this.tx = tx;
        this.blocks = blocks;
        this.subjects = subjects;
        this.completion = completion;
        this.logged = logged;
        this.events = events;
        this.zone = PlannerZone.of(zoneId);
        this.clock = clock;
    }

    /** Una sola instancia para los dos contratos; cada uno se expone envuelto en su transacción. */
    @Bean(autowireCandidate = false)
    PastActivityService pastActivityService() {
        return new PastActivityService(blocks, subjects, completion, zone, clock, logged, events);
    }

    @Bean
    LogPastActivityUseCase logPastActivityUseCase() {
        return tx.wrap(LogPastActivityUseCase.class, pastActivityService());
    }

    @Bean
    CompletePlannedActivityUseCase completePlannedActivityUseCase() {
        return tx.wrap(CompletePlannedActivityUseCase.class, pastActivityService());
    }

    @Bean
    ListSportActivitiesUseCase listSportActivitiesUseCase() {
        return tx.wrap(ListSportActivitiesUseCase.class, new SportActivityHistoryService(logged));
    }
}
