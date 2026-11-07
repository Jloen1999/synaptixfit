package com.synaptixfit.application.service.run;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.run.RecordRunUseCase;
import com.synaptixfit.domain.exception.planner.CalendarBlockNotFoundException;
import com.synaptixfit.domain.exception.run.RunOutOfRangeException;
import com.synaptixfit.domain.exception.run.RunTooShortException;
import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.run.PlannedRun;
import com.synaptixfit.domain.model.run.RecordedRun;
import com.synaptixfit.domain.model.run.RunDetail;
import com.synaptixfit.domain.model.run.RunStep;
import com.synaptixfit.domain.model.run.RunWeek;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.run.TrackPoint;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import com.synaptixfit.domain.port.output.run.RecordedRunRepositoryPort;
import com.synaptixfit.domain.port.output.run.RunWorkoutRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import java.lang.reflect.Proxy;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Guardar una carrera: se apunta como actividad con origen GPS, es idempotente con la clave del móvil y, si salió
 * de un evento con entreno de carrera, ese evento queda hecho.
 */
class RunServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-07T18:00:00Z");
    private static final double METERS_PER_DEGREE = Math.toRadians(1) * 6_371_008.8;
    private final UUID user = UUID.randomUUID();

    private final Map<UUID, RecordedRun> saved = new HashMap<>();
    private final List<LogPastActivityUseCase.Command> logged = new ArrayList<>();
    private final List<UUID> completed = new ArrayList<>();
    private final List<UUID> deleted = new ArrayList<>();
    private final List<ActivitySource> loggedSources = new ArrayList<>();
    private final Map<UUID, CalendarBlock> blocks = new HashMap<>();
    private final Map<UUID, UUID> eventWorkouts = new HashMap<>();
    private final Map<UUID, RunWorkout> workouts = new HashMap<>();
    private RunService service;

    @BeforeEach
    void setUp() {
        RecordedRunRepositoryPort runs = new RecordedRunRepositoryPort() {
            @Override
            public Optional<UUID> findBlockByClientKey(UUID userId, UUID clientKey) {
                return saved.values().stream().filter(r -> r.clientKey().equals(clientKey))
                        .map(RecordedRun::blockId).findFirst();
            }

            @Override
            public void save(RecordedRun run) {
                saved.put(run.blockId(), run);
            }

            @Override
            public Optional<RunDetail> findDetail(UUID userId, UUID blockId, int routePoints) {
                return Optional.ofNullable(saved.get(blockId)).map(r -> new RunDetail(blockId, r.kind(), null,
                        r.startedAt(), r.endedAt(), r.metrics().distanceMeters(), r.metrics().movingSeconds(),
                        r.metrics().elevationGainMeters(), r.kcal(), r.effort(), r.metrics().splits(), List.of(),
                        r.workoutId()));
            }

            @Override
            public List<RunWeek.Outing> findOutings(UUID userId, Instant from, Instant to) {
                return List.of();
            }
        };
        RunWorkoutRepositoryPort workoutRepo = new RunWorkoutRepositoryPort() {
            @Override
            public RunWorkout save(RunWorkout workout) {
                workouts.put(workout.id(), workout);
                return workout;
            }

            @Override
            public Optional<RunWorkout> findOwned(UUID userId, UUID workoutId) {
                return Optional.ofNullable(workouts.get(workoutId));
            }

            @Override
            public List<RunWorkout> findAll(UUID userId) {
                return List.copyOf(workouts.values());
            }

            @Override
            public void delete(UUID workoutId) {
                workouts.remove(workoutId);
            }

            @Override
            public void linkEvent(UUID blockId, UUID workoutId, UUID userId) {
                eventWorkouts.put(blockId, workoutId);
            }

            @Override
            public Optional<UUID> workoutOfEvent(UUID userId, UUID blockId) {
                return Optional.ofNullable(eventWorkouts.get(blockId));
            }

            @Override
            public List<PlannedRun> findPlanned(UUID userId, Instant from, Instant to) {
                return List.of();
            }
        };
        LogPastActivityUseCase logActivity = c -> {
            logged.add(c);
            CalendarBlock block = block(c.start(), Math.max(30, c.minutes()));
            return new SetBlockCompletionUseCase.Result(block, 15);
        };
        SetBlockCompletionUseCase completion = (userId, blockId, done, effort) -> {
            completed.add(blockId);
            return new SetBlockCompletionUseCase.Result(blocks.get(blockId), 15);
        };
        LoggedActivityRepositoryPort loggedRepo = new LoggedActivityRepositoryPort() {
            @Override
            public void save(UUID blockId, UUID userId, ActivityKind kind, int minutes, Integer distanceMeters,
                             ActivitySource source, Instant now) {
                loggedSources.add(source);
            }

            @Override
            public PageResult<LoggedSportActivity> findSportActivities(UUID userId, PageRequest page) {
                return new PageResult<>(List.of(), 0, 20, 0);
            }
        };
        TrainingContextPort context = (TrainingContextPort) Proxy.newProxyInstance(getClass().getClassLoader(),
                new Class<?>[] {TrainingContextPort.class}, (proxy, method, args) -> Optional.of(70.0));
        service = new RunService(runs, workoutRepo, logActivity, completion,
                (userId, blockId) -> Optional.ofNullable(blocks.get(blockId))
                        .orElseThrow(() -> new CalendarBlockNotFoundException(blockId)),
                (userId, blockId) -> deleted.add(blockId), loggedRepo, context, PlannerZone.of("Europe/Madrid"),
                Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private CalendarBlock block(Instant start, int minutes) {
        CalendarBlock b = CalendarBlock.builder().id(UUID.randomUUID()).userId(user)
                .range(TimeRange.ofMinutes(start, minutes)).type(ActivityType.SPORT)
                .details(new CalendarBlock.Details(null, "Series", null, Priority.MEDIUM, false, null, null, null,
                        null, null, null, null))
                .build();
        blocks.put(b.id(), b);
        return b;
    }

    /** {@code minutes} corriendo a 3 m/s, un punto cada 2 s. */
    private static List<TrackPoint> run(int minutes) {
        List<TrackPoint> points = new ArrayList<>();
        for (int s = 0; s <= minutes * 60; s += 2) {
            points.add(new TrackPoint(40.0 + 3.0 * s / METERS_PER_DEGREE, -3.7, 600.0, 5, s, 0));
        }
        return points;
    }

    private RecordRunUseCase.Command command(UUID key, Instant startedAt, int minutes, UUID workout, UUID planned) {
        return new RecordRunUseCase.Command(user, key, ActivityKind.RUN, startedAt, 7, run(minutes), workout,
                planned);
    }

    @Test
    void aRunIsLoggedAsAnActivityFromTheGpsEndingWhenItEnded() {
        Instant startedAt = NOW.minus(Duration.ofMinutes(40));
        RecordRunUseCase.Result result = service.recordRun(command(UUID.randomUUID(), startedAt, 25, null, null));

        assertThat(logged).hasSize(1);
        LogPastActivityUseCase.Command c = logged.getFirst();
        assertThat(c.source()).isEqualTo(ActivitySource.GPS);
        assertThat(c.type()).isEqualTo(ActivityType.SPORT);
        assertThat(c.kind()).isEqualTo(ActivityKind.RUN);
        assertThat(c.minutes()).isEqualTo(25);
        assertThat(c.effort()).isEqualTo(7);
        assertThat(c.start()).isEqualTo(startedAt);
        assertThat(c.distanceMeters()).isBetween(4490, 4510);
        assertThat(result.xpDelta()).isEqualTo(15);
        assertThat(result.run().distanceMeters()).isBetween(4490, 4510);
        // 25 min a 10,8 km/h y 70 kg: ≈ 11,3 MET · 70 · 0,417 h ≈ 330 kcal.
        assertThat(saved.values().iterator().next().kcal()).isBetween(320, 340);
    }

    @Test
    void sendingTheSameRunTwiceDoesNotDuplicateIt() {
        UUID key = UUID.randomUUID();
        Instant startedAt = NOW.minus(Duration.ofHours(1));
        RecordRunUseCase.Result first = service.recordRun(command(key, startedAt, 20, null, null));
        RecordRunUseCase.Result again = service.recordRun(command(key, startedAt, 20, null, null));

        assertThat(logged).hasSize(1);
        assertThat(saved).hasSize(1);
        assertThat(again.run().blockId()).isEqualTo(first.run().blockId());
        assertThat(again.xpDelta()).isZero();
    }

    @Test
    void lessThanTenMinutesMovingDoesNotCount() {
        assertThatThrownBy(() -> service.recordRun(command(UUID.randomUUID(), NOW.minus(Duration.ofHours(1)), 8,
                null, null))).isInstanceOf(RunTooShortException.class);
        assertThat(logged).isEmpty();
    }

    @Test
    void runsOlderThanThirtyDaysOrInTheFutureAreRejected() {
        assertThatThrownBy(() -> service.recordRun(command(UUID.randomUUID(), NOW.minus(Duration.ofDays(31)), 20,
                null, null))).isInstanceOf(RunOutOfRangeException.class);
        assertThatThrownBy(() -> service.recordRun(command(UUID.randomUUID(), NOW.minus(Duration.ofMinutes(5)), 20,
                null, null))).isInstanceOf(RunOutOfRangeException.class);
    }

    @Test
    void aPlannedEventThatAlreadyStartedEndsUpDone() {
        RunWorkout workout = new RunWorkout(UUID.randomUUID(), user, "Series 6 × 800 m", "INTERVALS_6X800",
                List.of(RunWorkout.Group.once(RunStep.time(RunStep.Type.RUN, 1200))), NOW, NOW);
        workouts.put(workout.id(), workout);
        CalendarBlock event = block(NOW.minus(Duration.ofMinutes(45)), 60);
        eventWorkouts.put(event.id(), workout.id());

        RecordRunUseCase.Result result = service.recordRun(command(UUID.randomUUID(),
                NOW.minus(Duration.ofMinutes(40)), 30, null, event.id()));

        assertThat(completed).containsExactly(event.id());
        assertThat(logged).isEmpty();
        assertThat(loggedSources).containsExactly(ActivitySource.GPS);
        assertThat(result.run().blockId()).isEqualTo(event.id());
        assertThat(result.run().workoutId()).isEqualTo(workout.id());
    }

    @Test
    void runningBeforeTheEventTimeLogsItNowAndRemovesTheEvent() {
        RunWorkout workout = new RunWorkout(UUID.randomUUID(), user, "Rodaje suave", "EASY_30",
                List.of(RunWorkout.Group.once(RunStep.time(RunStep.Type.RUN, 1800))), NOW, NOW);
        workouts.put(workout.id(), workout);
        CalendarBlock later = block(NOW.plus(Duration.ofHours(2)), 40);
        eventWorkouts.put(later.id(), workout.id());

        service.recordRun(command(UUID.randomUUID(), NOW.minus(Duration.ofMinutes(40)), 30, null, later.id()));

        assertThat(deleted).containsExactly(later.id());
        assertThat(completed).isEmpty();
        assertThat(logged).hasSize(1);
        assertThat(logged.getFirst().title()).isEqualTo("Rodaje suave");
    }

    @Test
    void weekStartsOnMonday() {
        assertThat(service.getWeek(user, LocalDate.parse("2026-11-07")).weekStart())
                .isEqualTo(LocalDate.parse("2026-11-02"));
    }
}
