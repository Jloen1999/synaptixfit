package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.AddSessionExerciseUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.GetStartingLoadsUseCase;
import com.synaptixfit.application.port.input.training.SaveSessionAsRoutineUseCase;
import com.synaptixfit.application.port.input.training.StartFreeSessionUseCase;
import com.synaptixfit.application.service.training.FreeSessionService;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de la sesión libre con ejercicios (ADR 0067): empezarla con su lista, sumar ejercicios y guardarla. */
@Configuration
public class FreeSessionBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final FreeSessionService service;

    public FreeSessionBeanConfiguration(TransactionalUseCaseFactory tx, TrainingSessionRepositoryPort sessions,
                                        RoutineRepositoryPort routines, ExerciseRepositoryPort exercises,
                                        RoutineTemplateRepositoryPort templates,
                                        GetStartingLoadsUseCase startingLoads, CreateRoutineUseCase createRoutine,
                                        Clock clock,
                                        @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.service = new FreeSessionService(sessions, routines, exercises, templates, startingLoads, createRoutine,
                clock, ZoneId.of(zone));
    }

    @Bean
    StartFreeSessionUseCase startFreeSessionUseCase() {
        return tx.wrap(StartFreeSessionUseCase.class, service);
    }

    @Bean
    AddSessionExerciseUseCase addSessionExerciseUseCase() {
        return tx.wrap(AddSessionExerciseUseCase.class, service);
    }

    @Bean
    SaveSessionAsRoutineUseCase saveSessionAsRoutineUseCase() {
        return tx.wrap(SaveSessionAsRoutineUseCase.class, service);
    }
}
