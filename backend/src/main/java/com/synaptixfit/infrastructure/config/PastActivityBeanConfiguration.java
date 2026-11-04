package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.planner.ListSportActivitiesUseCase;
import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.service.planner.PastActivityService;
import com.synaptixfit.application.service.planner.SportActivityHistoryService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de «Apuntar una actividad pasada» y del deporte hecho para el historial (planificador). */
@Configuration
public class PastActivityBeanConfiguration {

    @Bean
    LogPastActivityUseCase logPastActivityUseCase(TransactionalUseCaseFactory tx, CalendarBlockRepositoryPort blocks,
                                                  SubjectDirectoryPort subjects,
                                                  SetBlockCompletionUseCase completion,
                                                  LoggedActivityRepositoryPort logged,
                                                  @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId,
                                                  Clock clock) {
        return tx.wrap(LogPastActivityUseCase.class,
                new PastActivityService(blocks, subjects, completion, PlannerZone.of(zoneId), clock, logged));
    }

    @Bean
    ListSportActivitiesUseCase listSportActivitiesUseCase(TransactionalUseCaseFactory tx,
                                                          LoggedActivityRepositoryPort logged) {
        return tx.wrap(ListSportActivitiesUseCase.class, new SportActivityHistoryService(logged));
    }
}
