package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.CalibrateExerciseUseCase;
import com.synaptixfit.application.port.input.training.GetStartingLoadsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionCalibrationsUseCase;
import com.synaptixfit.application.service.training.ExerciseCalibrationService;
import com.synaptixfit.application.service.training.StartingLoadService;
import com.synaptixfit.domain.port.output.training.ExerciseCalibrationRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseLoadProfileRepositoryPort;
import com.synaptixfit.domain.port.output.training.HealthConsentRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición del peso de partida y de la calibración de la primera sesión de cada ejercicio (ADR 0054). */
@Configuration
public class TrainingLoadBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final ExerciseLoadProfileRepositoryPort profiles;
    private final ExerciseCalibrationRepositoryPort calibrations;
    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final TrainingContextPort context;
    private final HealthConsentRepositoryPort consents;
    private final Clock clock;

    public TrainingLoadBeanConfiguration(TransactionalUseCaseFactory tx, ExerciseLoadProfileRepositoryPort profiles,
                                         ExerciseCalibrationRepositoryPort calibrations,
                                         TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                         TrainingContextPort context, HealthConsentRepositoryPort consents,
                                         Clock clock) {
        this.tx = tx;
        this.profiles = profiles;
        this.calibrations = calibrations;
        this.sessions = sessions;
        this.routines = routines;
        this.context = context;
        this.consents = consents;
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    StartingLoadService startingLoadService() {
        return new StartingLoadService(profiles, sessions, context, consents, clock);
    }

    @Bean
    GetStartingLoadsUseCase getStartingLoadsUseCase() {
        return tx.wrap(GetStartingLoadsUseCase.class, startingLoadService());
    }

    @Bean(autowireCandidate = false)
    ExerciseCalibrationService exerciseCalibrationService() {
        return new ExerciseCalibrationService(sessions, routines, calibrations, clock);
    }

    @Bean
    ListSessionCalibrationsUseCase listSessionCalibrationsUseCase() {
        return tx.wrap(ListSessionCalibrationsUseCase.class, exerciseCalibrationService());
    }

    @Bean
    CalibrateExerciseUseCase calibrateExerciseUseCase() {
        return tx.wrap(CalibrateExerciseUseCase.class, exerciseCalibrationService());
    }
}
