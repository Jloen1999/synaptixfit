package com.synaptixfit.application.service.run;

import com.synaptixfit.application.port.input.planner.CompletePlannedActivityUseCase;
import com.synaptixfit.application.port.input.planner.DeleteCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.run.DeleteRunUseCase;
import com.synaptixfit.application.port.input.run.GetRunUseCase;
import com.synaptixfit.application.port.input.run.GetRunWeekUseCase;
import com.synaptixfit.application.port.input.run.RecordRunUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.planner.CalendarBlockNotFoundException;
import com.synaptixfit.domain.exception.run.RunNotFoundException;
import com.synaptixfit.domain.exception.run.RunOutOfRangeException;
import com.synaptixfit.domain.exception.run.RunTooShortException;
import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PastActivity;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.run.RecordedRun;
import com.synaptixfit.domain.model.run.RunDetail;
import com.synaptixfit.domain.model.run.RunEnergy;
import com.synaptixfit.domain.model.run.RunMetrics;
import com.synaptixfit.domain.model.run.RunTrack;
import com.synaptixfit.domain.model.run.RunWeek;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.run.RecordedRunRepositoryPort;
import com.synaptixfit.domain.port.output.run.RunWorkoutRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Implementa las carreras con GPS (ADR 0037): {@link RecordRunUseCase}, {@link GetRunUseCase},
 * {@link DeleteRunUseCase} y {@link GetRunWeekUseCase}.
 *
 * <p>Una carrera es una actividad: se apunta con {@link LogPastActivityUseCase} (origen GPS), así suma racha, XP,
 * carga física (esfuerzo × minutos en movimiento, el mismo modelo que alimenta el ACWR), retos ligados y la semana
 * igual que cualquier otra. Si se grabó desde un evento con entreno de carrera:
 * <ul>
 *   <li>si el evento ya había empezado, ese evento queda hecho como actividad
 *   ({@link CompletePlannedActivityUseCase}) y la carrera se guarda en él;</li>
 *   <li>si aún no había empezado (se corrió antes de la hora), el evento se borra y la carrera se apunta en su hora
 *   real: el planificador no mueve eventos al pasado y así no quedan dos cosas para lo mismo.</li>
 * </ul>
 */
public class RunService implements RecordRunUseCase, GetRunUseCase, DeleteRunUseCase, GetRunWeekUseCase {

    /** Clases que se graban con el GPS. */
    static final Set<ActivityKind> GPS_KINDS = Set.of(ActivityKind.RUN, ActivityKind.WALK, ActivityKind.BIKE);
    /** Margen para relojes del móvil algo adelantados. */
    static final Duration CLOCK_SKEW = Duration.ofMinutes(2);

    private final RecordedRunRepositoryPort runs;
    private final RunWorkoutRepositoryPort workouts;
    private final LogPastActivityUseCase logActivity;
    private final CompletePlannedActivityUseCase completePlanned;
    private final GetCalendarBlockUseCase getBlock;
    private final DeleteCalendarBlockUseCase deleteBlock;
    private final TrainingContextPort context;
    private final PlannerZone zone;
    private final Clock clock;

    public RunService(RecordedRunRepositoryPort runs, RunWorkoutRepositoryPort workouts,
                      LogPastActivityUseCase logActivity, CompletePlannedActivityUseCase completePlanned,
                      GetCalendarBlockUseCase getBlock, DeleteCalendarBlockUseCase deleteBlock,
                      TrainingContextPort context, PlannerZone zone, Clock clock) {
        this.runs = runs;
        this.workouts = workouts;
        this.logActivity = logActivity;
        this.completePlanned = completePlanned;
        this.getBlock = getBlock;
        this.deleteBlock = deleteBlock;
        this.context = context;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public Result recordRun(Command command) {
        Guard.notNull(command.clientKey(), "clientKey");
        Guard.notNull(command.startedAt(), "startedAt");
        Optional<UUID> existing = runs.findBlockByClientKey(command.userId(), command.clientKey());
        if (existing.isPresent()) {
            return new Result(getRun(command.userId(), existing.get()), 0);
        }
        if (command.kind() == null || !GPS_KINDS.contains(command.kind())) {
            throw new FieldValidationException("kind", "NOT_ALLOWED", "GPS runs are RUN, WALK or BIKE");
        }
        int effort = Guard.range(command.effort(), "effort", 1, 10);
        RunMetrics metrics = RunTrack.analyze(command.points(), command.kind());
        int minutes = metrics.movingMinutes();
        if (minutes < PastActivity.MIN_SPORT_MINUTES) {
            throw new RunTooShortException();
        }
        if (minutes > PastActivity.MAX_MINUTES) {
            throw new FieldValidationException("points", "OUT_OF_RANGE",
                    "a run can last up to " + PastActivity.MAX_MINUTES + " minutes moving");
        }
        Instant now = clock.instant();
        Instant firstPoint = command.startedAt().plusMillis(
                Math.round(metrics.points().getFirst().offsetSeconds() * 1000));
        Instant end = command.startedAt().plusMillis(Math.round(metrics.points().getLast().offsetSeconds() * 1000));
        if (end.isAfter(now.plus(CLOCK_SKEW))
                || firstPoint.isBefore(now.minus(Duration.ofDays(ActivitySource.GPS.maxDaysBack())))) {
            throw new RunOutOfRangeException();
        }
        if (end.isAfter(now)) {
            end = now;
        }
        UUID userId = command.userId();
        RunWorkout workout = Optional.ofNullable(command.workoutId())
                .flatMap(id -> workouts.findOwned(userId, id))
                .orElse(null);
        Integer distance = metrics.distanceMeters() >= PastActivity.MIN_DISTANCE_METERS
                ? Math.min(metrics.distanceMeters(), PastActivity.MAX_DISTANCE_METERS) : null;

        UUID blockId = null;
        int xpDelta = 0;
        if (command.plannedBlockId() != null) {
            Optional<UUID> plannedWorkout = workouts.workoutOfEvent(userId, command.plannedBlockId());
            Optional<CalendarBlock> planned = plannedWorkout.flatMap(w -> findBlock(userId, command.plannedBlockId()));
            if (planned.isPresent() && !planned.get().completed()) {
                if (planned.get().start().isAfter(now)) {
                    deleteBlock.deleteBlock(userId, planned.get().id());
                } else {
                    SetBlockCompletionUseCase.Result done = completePlanned.completePlannedActivity(
                            new CompletePlannedActivityUseCase.Command(userId, planned.get().id(), effort,
                                    command.kind(), minutes, distance, ActivitySource.GPS));
                    blockId = planned.get().id();
                    xpDelta = done.xpDelta();
                }
                if (workout == null) {
                    workout = workouts.findOwned(userId, plannedWorkout.get()).orElse(null);
                }
            }
        }
        if (blockId == null) {
            SetBlockCompletionUseCase.Result result = logActivity.logPastActivity(new LogPastActivityUseCase.Command(
                    userId, end.minus(Duration.ofMinutes(minutes)), minutes, workout == null ? null : workout.name(),
                    effort, ActivityType.SPORT, null, command.kind(), distance, ActivitySource.GPS));
            blockId = result.block().id();
            xpDelta = result.xpDelta();
        }
        Double weight = context.bodyWeightKg(userId).orElse(null);
        runs.save(new RecordedRun(blockId, userId, command.clientKey(), command.kind(), firstPoint, end, metrics,
                RunEnergy.kcal(command.kind(), metrics, weight), effort, workout == null ? null : workout.id(), now));
        return new Result(getRun(userId, blockId), xpDelta);
    }

    private Optional<CalendarBlock> findBlock(UUID userId, UUID blockId) {
        try {
            return Optional.of(getBlock.getBlock(userId, blockId));
        } catch (CalendarBlockNotFoundException e) {
            return Optional.empty();
        }
    }

    @Override
    public RunDetail getRun(UUID userId, UUID blockId) {
        return runs.findDetail(userId, blockId, RunDetail.ROUTE_POINTS)
                .orElseThrow(() -> new RunNotFoundException(blockId));
    }

    @Override
    public void deleteRun(UUID userId, UUID blockId) {
        getRun(userId, blockId);
        deleteBlock.deleteBlock(userId, blockId);
    }

    @Override
    public RunWeek getWeek(UUID userId, LocalDate date) {
        LocalDate day = date == null ? zone.today(clock.instant()) : date;
        LocalDate monday = PlannerZone.mondayOf(day);
        return RunWeek.of(monday, runs.findOutings(userId, zone.startOfDay(monday),
                zone.startOfDay(monday.plusDays(7))), zone);
    }
}
