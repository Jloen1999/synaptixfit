package com.synaptixfit.application.service.run;

import com.synaptixfit.application.port.input.planner.BlockChange;
import com.synaptixfit.application.port.input.planner.BlockDetailsInput;
import com.synaptixfit.application.port.input.planner.CreateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.run.CreateRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.DeleteRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.ListPlannedRunsUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutTemplatesUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutsUseCase;
import com.synaptixfit.application.port.input.run.ScheduleRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.UpdateRunWorkoutUseCase;
import com.synaptixfit.domain.exception.run.RunWorkoutNotFoundException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.run.PlannedRun;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.run.RunWorkoutTemplates;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.run.RunWorkoutRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Implementa los entrenos de carrera por pasos (ADR 0037): listar, plantillas, crear, cambiar, borrar, «Poner en el
 * calendario» (con {@link CreateCalendarBlockUseCase}, el contrato del planificador) y los que quedan por hacer.
 */
public class RunWorkoutService implements ListRunWorkoutsUseCase, ListRunWorkoutTemplatesUseCase,
        CreateRunWorkoutUseCase, UpdateRunWorkoutUseCase, DeleteRunWorkoutUseCase, ScheduleRunWorkoutUseCase,
        ListPlannedRunsUseCase {

    /** «Hoy toca…» mira hoy y los 7 días siguientes. */
    static final int PLANNED_DAYS = 8;
    /** Un evento con entreno de carrera dura lo previsto, entre el mínimo del calendario y 5 horas. */
    static final int MAX_EVENT_MINUTES = 300;

    private final RunWorkoutRepositoryPort workouts;
    private final CreateCalendarBlockUseCase createBlock;
    private final PlannerZone zone;
    private final Clock clock;

    public RunWorkoutService(RunWorkoutRepositoryPort workouts, CreateCalendarBlockUseCase createBlock,
                             PlannerZone zone, Clock clock) {
        this.workouts = workouts;
        this.createBlock = createBlock;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public List<RunWorkout> listWorkouts(UUID userId) {
        return workouts.findAll(userId);
    }

    @Override
    public List<RunWorkoutTemplates.Template> listTemplates() {
        return RunWorkoutTemplates.ALL;
    }

    @Override
    public RunWorkout createWorkout(CreateRunWorkoutUseCase.Command command) {
        String template = command.templateCode();
        if (template != null && RunWorkoutTemplates.ALL.stream().noneMatch(t -> t.code().equals(template))) {
            throw new RunWorkoutNotFoundException(template);
        }
        Instant now = clock.instant();
        return workouts.save(new RunWorkout(UUID.randomUUID(), command.userId(), command.name(), template,
                command.groups(), now, now));
    }

    @Override
    public RunWorkout updateWorkout(UpdateRunWorkoutUseCase.Command command) {
        RunWorkout current = owned(command.userId(), command.workoutId());
        return workouts.save(current.renamed(command.name(), command.groups(), clock.instant()));
    }

    @Override
    public void deleteWorkout(UUID userId, UUID workoutId) {
        workouts.delete(owned(userId, workoutId).id());
    }

    @Override
    public BlockChange scheduleWorkout(UUID userId, UUID workoutId, Instant start) {
        Guard.notNull(start, "start");
        RunWorkout workout = owned(userId, workoutId);
        long minutes = Math.min(MAX_EVENT_MINUTES,
                Math.max(TimeRange.MIN_MINUTES, (long) Math.ceil(workout.estimatedSeconds() / 60.0)));
        BlockDetailsInput details = new BlockDetailsInput(ActivityType.SPORT, null, workout.name(), null,
                Priority.MEDIUM, false, null, null, null, null, null, null, null, null, null);
        BlockChange change = createBlock.createBlock(new CreateCalendarBlockUseCase.Command(userId, start,
                start.plus(Duration.ofMinutes(minutes)), false, details));
        workouts.linkEvent(change.block().id(), workout.id(), userId);
        return change;
    }

    @Override
    public List<PlannedRun> listPlanned(UUID userId) {
        LocalDate today = zone.today(clock.instant());
        return workouts.findPlanned(userId, zone.startOfDay(today), zone.startOfDay(today.plusDays(PLANNED_DAYS)));
    }

    private RunWorkout owned(UUID userId, UUID workoutId) {
        return workouts.findOwned(userId, workoutId).orElseThrow(() -> new RunWorkoutNotFoundException(workoutId));
    }
}
