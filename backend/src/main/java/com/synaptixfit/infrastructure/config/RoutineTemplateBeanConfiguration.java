package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.CreateRoutineFromTemplateUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.ListRoutineTemplatesUseCase;
import com.synaptixfit.application.service.training.RoutineTemplateService;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de las plantillas de rutina listas para usar (ADR 0032). */
@Configuration
public class RoutineTemplateBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final RoutineTemplateRepositoryPort templates;
    private final CreateRoutineUseCase createRoutine;

    public RoutineTemplateBeanConfiguration(TransactionalUseCaseFactory tx, RoutineTemplateRepositoryPort templates,
                                            CreateRoutineUseCase createRoutine) {
        this.tx = tx;
        this.templates = templates;
        this.createRoutine = createRoutine;
    }

    @Bean(autowireCandidate = false)
    RoutineTemplateService routineTemplateService() {
        return new RoutineTemplateService(templates, createRoutine);
    }

    @Bean
    ListRoutineTemplatesUseCase listRoutineTemplatesUseCase() {
        return tx.wrap(ListRoutineTemplatesUseCase.class, routineTemplateService());
    }

    @Bean
    CreateRoutineFromTemplateUseCase createRoutineFromTemplateUseCase() {
        return tx.wrap(CreateRoutineFromTemplateUseCase.class, routineTemplateService());
    }
}
