package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.run.CreateRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutsUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineFromTemplateUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineTemplateUseCase;
import com.synaptixfit.application.port.input.training.GetStartingLoadsUseCase;
import com.synaptixfit.application.port.input.training.ListRoutineTemplatesUseCase;
import com.synaptixfit.application.service.training.RoutineTemplateDetailService;
import com.synaptixfit.application.service.training.RoutineTemplateService;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de las plantillas de rutina listas para usar (ADR 0032, 0043: con entrenos de carrera; 0054: con peso de
 * partida).
 */
@Configuration
public class RoutineTemplateBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final RoutineTemplateRepositoryPort templates;
    private final CreateRoutineUseCase createRoutine;
    private final ListRunWorkoutsUseCase listRunWorkouts;
    private final CreateRunWorkoutUseCase createRunWorkout;
    private final GetStartingLoadsUseCase startingLoads;
    private final ExerciseRepositoryPort exercises;

    public RoutineTemplateBeanConfiguration(TransactionalUseCaseFactory tx, RoutineTemplateRepositoryPort templates,
                                            CreateRoutineUseCase createRoutine, ListRunWorkoutsUseCase listRunWorkouts,
                                            CreateRunWorkoutUseCase createRunWorkout,
                                            GetStartingLoadsUseCase startingLoads, ExerciseRepositoryPort exercises) {
        this.exercises = exercises;
        this.tx = tx;
        this.templates = templates;
        this.createRoutine = createRoutine;
        this.listRunWorkouts = listRunWorkouts;
        this.createRunWorkout = createRunWorkout;
        this.startingLoads = startingLoads;
    }

    @Bean(autowireCandidate = false)
    RoutineTemplateService routineTemplateService() {
        return new RoutineTemplateService(templates, createRoutine, listRunWorkouts, createRunWorkout,
                startingLoads);
    }

    @Bean
    ListRoutineTemplatesUseCase listRoutineTemplatesUseCase() {
        return tx.wrap(ListRoutineTemplatesUseCase.class, routineTemplateService());
    }

    @Bean
    CreateRoutineFromTemplateUseCase createRoutineFromTemplateUseCase() {
        return tx.wrap(CreateRoutineFromTemplateUseCase.class, routineTemplateService());
    }

    @Bean
    GetRoutineTemplateUseCase getRoutineTemplateUseCase() {
        return tx.wrap(GetRoutineTemplateUseCase.class, new RoutineTemplateDetailService(templates, exercises));
    }
}
