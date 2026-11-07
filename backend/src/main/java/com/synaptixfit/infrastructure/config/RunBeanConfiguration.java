package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.planner.CreateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.run.CreateRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.DeleteRunUseCase;
import com.synaptixfit.application.port.input.run.DeleteRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.GetRunUseCase;
import com.synaptixfit.application.port.input.run.GetRunWeekUseCase;
import com.synaptixfit.application.port.input.run.ListPlannedRunsUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutTemplatesUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutsUseCase;
import com.synaptixfit.application.port.input.run.RecordRunUseCase;
import com.synaptixfit.application.port.input.run.ScheduleRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.UpdateRunWorkoutUseCase;
import com.synaptixfit.application.service.run.RunService;
import com.synaptixfit.application.service.run.RunWorkoutService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import com.synaptixfit.domain.port.output.run.RecordedRunRepositoryPort;
import com.synaptixfit.domain.port.output.run.RunWorkoutRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de las carreras con GPS y de los entrenos de carrera (ADR 0037). Usan el planificador solo por sus
 * contratos: apuntar actividad, completar, leer, crear y borrar eventos.
 */
@Configuration
public class RunBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final RecordedRunRepositoryPort runs;
    private final RunWorkoutRepositoryPort workouts;
    private final LogPastActivityUseCase logActivity;
    private final SetBlockCompletionUseCase completion;
    private final GetCalendarBlockUseCase getBlock;
    private final CreateCalendarBlockUseCase createBlock;
    private final DeleteCalendarBlockUseCase deleteBlock;
    private final LoggedActivityRepositoryPort logged;
    private final TrainingContextPort context;
    private final PlannerZone zone;
    private final Clock clock;

    public RunBeanConfiguration(TransactionalUseCaseFactory tx, RecordedRunRepositoryPort runs,
                                RunWorkoutRepositoryPort workouts, LogPastActivityUseCase logActivity,
                                SetBlockCompletionUseCase completion, GetCalendarBlockUseCase getBlock,
                                CreateCalendarBlockUseCase createBlock, DeleteCalendarBlockUseCase deleteBlock,
                                LoggedActivityRepositoryPort logged, TrainingContextPort context,
                                @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId, Clock clock) {
        this.tx = tx;
        this.runs = runs;
        this.workouts = workouts;
        this.logActivity = logActivity;
        this.completion = completion;
        this.getBlock = getBlock;
        this.createBlock = createBlock;
        this.deleteBlock = deleteBlock;
        this.logged = logged;
        this.context = context;
        this.zone = PlannerZone.of(zoneId);
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    RunService runService() {
        return new RunService(runs, workouts, logActivity, completion, getBlock, deleteBlock, logged, context, zone,
                clock);
    }

    @Bean(autowireCandidate = false)
    RunWorkoutService runWorkoutService() {
        return new RunWorkoutService(workouts, createBlock, zone, clock);
    }

    @Bean
    RecordRunUseCase recordRunUseCase() {
        return tx.wrap(RecordRunUseCase.class, runService());
    }

    @Bean
    GetRunUseCase getRunUseCase() {
        return tx.wrap(GetRunUseCase.class, runService());
    }

    @Bean
    DeleteRunUseCase deleteRunUseCase() {
        return tx.wrap(DeleteRunUseCase.class, runService());
    }

    @Bean
    GetRunWeekUseCase getRunWeekUseCase() {
        return tx.wrap(GetRunWeekUseCase.class, runService());
    }

    @Bean
    ListRunWorkoutsUseCase listRunWorkoutsUseCase() {
        return tx.wrap(ListRunWorkoutsUseCase.class, runWorkoutService());
    }

    @Bean
    ListRunWorkoutTemplatesUseCase listRunWorkoutTemplatesUseCase() {
        return tx.wrap(ListRunWorkoutTemplatesUseCase.class, runWorkoutService());
    }

    @Bean
    CreateRunWorkoutUseCase createRunWorkoutUseCase() {
        return tx.wrap(CreateRunWorkoutUseCase.class, runWorkoutService());
    }

    @Bean
    UpdateRunWorkoutUseCase updateRunWorkoutUseCase() {
        return tx.wrap(UpdateRunWorkoutUseCase.class, runWorkoutService());
    }

    @Bean
    DeleteRunWorkoutUseCase deleteRunWorkoutUseCase() {
        return tx.wrap(DeleteRunWorkoutUseCase.class, runWorkoutService());
    }

    @Bean
    ScheduleRunWorkoutUseCase scheduleRunWorkoutUseCase() {
        return tx.wrap(ScheduleRunWorkoutUseCase.class, runWorkoutService());
    }

    @Bean
    ListPlannedRunsUseCase listPlannedRunsUseCase() {
        return tx.wrap(ListPlannedRunsUseCase.class, runWorkoutService());
    }
}
