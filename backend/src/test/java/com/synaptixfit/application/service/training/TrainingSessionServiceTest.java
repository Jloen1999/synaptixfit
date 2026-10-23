package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.FinishTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.exception.training.RoutineExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import com.synaptixfit.domain.exception.training.SessionDayMismatchException;
import com.synaptixfit.domain.exception.training.SessionNotCompletedException;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.training.RecommendationType;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.SessionType;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class TrainingSessionServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final UUID OTHER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-05T18:00:00Z");

    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final TrainingFakes.Recommendations recommendations = new TrainingFakes.Recommendations();
    private final List<DomainEvent> events = new ArrayList<>();
    private final List<Integer> awarded = new ArrayList<>();
    private final List<Integer> revoked = new ArrayList<>();
    private Double weight = 80.0;
    private TrainingSessionService service;
    private Routine routine;
    private RoutineDay day1;
    private RoutineDay day2;

    @BeforeEach
    void setUp() {
        TrainingContextPort context = new TrainingContextPort() {
            public Optional<Double> bodyWeightKg(UUID userId) { return Optional.ofNullable(weight); }
            public Optional<TrainingProfile> profile(UUID userId) { return Optional.empty(); }
            public AcademicContext academicContext(UUID userId, LocalDate today) { return AcademicContext.NONE; }
            public PhysiologicalContext physiologicalContext(UUID userId, LocalDate today) { return PhysiologicalContext.NONE; }
            public Optional<GoalChange> latestGoalChange(UUID userId) { return Optional.empty(); }
        };
        service = new TrainingSessionService(sessions, routines, recommendations, context,
                (userId, amount) -> {
                    awarded.add(amount);
                    return new ExperienceChange(1, amount, 0, amount);
                },
                (userId, amount) -> {
                    revoked.add(amount);
                    return new ExperienceChange(1, 0, 0, -amount);
                },
                events::add, Clock.fixed(NOW, ZoneOffset.UTC), ZoneOffset.UTC);

        var bench = TrainingFakes.strength("Press de banca", "Pectoral mayor").toRef();
        day1 = RoutineDay.create(1, "Torso");
        day1.addExercise(bench, new ExerciseParameters(3, 10, 90, 50.0, null, null, null, null));
        day2 = RoutineDay.create(2, "Pierna");
        day2.addExercise(bench, new ExerciseParameters(3, 10, 90, 50.0, null, null, null, null));
        routine = routines.save(Routine.create(USER, "Mi rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(day1, day2))), NOW));
    }

    private PlannedExercise planned(RoutineDay day) {
        return routine.day(day.id()).exercises().getFirst();
    }

    @Test
    void startMarksDayInProgressAndSetsStartDateAndIsIdempotent() {
        TrainingSession s = service.start(USER, routine.id(), day1.id());
        assertThat(s.type()).isEqualTo(SessionType.ROUTINE);
        assertThat(s.isCompleted()).isFalse();
        assertThat(routine.day(day1.id()).status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        assertThat(routine.weeks().getFirst().status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        assertThat(routine.startDate()).isEqualTo(LocalDate.of(2026, 10, 5));
        assertThat(service.start(USER, routine.id(), day1.id()).id()).isEqualTo(s.id());
    }

    @Test
    void startValidatesOwnershipAndDay() {
        assertThatThrownBy(() -> service.start(OTHER, routine.id(), day1.id())).isInstanceOf(RoutineNotFoundException.class);
        assertThatThrownBy(() -> service.start(USER, routine.id(), UUID.randomUUID()))
                .isInstanceOf(SessionDayMismatchException.class);
        assertThatThrownBy(() -> service.start(USER, null, day1.id())).isInstanceOf(SessionDayMismatchException.class);
        assertThat(service.start(USER, null, null).type()).isEqualTo(SessionType.FREE);
    }

    @Test
    void startAfterLongInactivitySuggestsDeload() {
        sessions.lastCompleted = NOW.minusSeconds(20L * 86_400);
        service.start(USER, routine.id(), day1.id());
        assertThat(recommendations.store.values()).singleElement()
                .satisfies(r -> {
                    assertThat(r.type()).isEqualTo(RecommendationType.DELOAD);
                    assertThat(r.adjustments()).singleElement()
                            .satisfies(a -> assertThat(a.parameters().weightKg()).isEqualTo(40.0));
                });
    }

    @Test
    void finishCompletesDayAwardsXpComputesCaloriesAndPublishesEvent() {
        TrainingSession s = service.start(USER, routine.id(), day1.id());
        UUID plannedId = planned(day1).id();
        FinishTrainingSessionUseCase.Result result = service.finish(new FinishTrainingSessionUseCase.Command(USER,
                s.id(), 2700, 7, Map.of(plannedId, 600),
                List.of(new RecordSessionSetUseCase.Command(USER, s.id(), plannedId, 1, 10, 50.0, true, 0))));

        int expectedXp = 50 + 45 + 7 * 5;
        assertThat(result.session().isCompleted()).isTrue();
        assertThat(result.session().durationMinutes()).isEqualTo(45);
        assertThat(result.session().xpAwarded()).isEqualTo(expectedXp);
        assertThat(awarded).containsExactly(expectedXp);
        // 600 s a MET 6 + 2 descansos de 90 s a MET 1,5, con 80 kg.
        double expectedKcal = 6.0 * 80 * 600 / 3600 + 1.5 * 80 * 180 / 3600;
        assertThat(result.session().calories()).isCloseTo(expectedKcal, org.assertj.core.data.Offset.offset(0.1));
        assertThat(routine.day(day1.id()).status()).isEqualTo(ProgressStatus.COMPLETED);
        assertThat(routine.weeks().getFirst().status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        assertThat(routine.plannedExercise(plannedId).realDurationSeconds()).isEqualTo(600);
        assertThat(events).singleElement().isInstanceOfSatisfying(TrainingSessionCompletionChanged.class, e -> {
            assertThat(e.completed()).isTrue();
            assertThat(e.rpe()).isEqualTo(7);
            assertThat(e.durationMinutes()).isEqualTo(45);
            assertThat(e.date()).isEqualTo(LocalDate.of(2026, 10, 5));
        });
        assertThat(result.recommendations()).singleElement()
                .satisfies(r -> assertThat(r.type()).isEqualTo(RecommendationType.PROGRESSION));
        assertThatThrownBy(() -> service.finish(new FinishTrainingSessionUseCase.Command(USER, s.id(), 60, 5, null, null)))
                .isInstanceOf(SessionAlreadyCompletedException.class);
    }

    @Test
    void completingAllDaysCompletesTheWeek() {
        TrainingSession a = service.start(USER, routine.id(), day1.id());
        service.finish(new FinishTrainingSessionUseCase.Command(USER, a.id(), 1800, 6, null, null));
        TrainingSession b = service.start(USER, routine.id(), day2.id());
        service.finish(new FinishTrainingSessionUseCase.Command(USER, b.id(), 1800, 6, null, null));
        assertThat(routine.weeks().getFirst().status()).isEqualTo(ProgressStatus.COMPLETED);
    }

    @Test
    void unmarkRevokesExactlyTheAwardedXpAndPublishesInverseEvent() {
        TrainingSession s = service.start(USER, routine.id(), day1.id());
        service.finish(new FinishTrainingSessionUseCase.Command(USER, s.id(), 7200, 10, null, null));
        int granted = awarded.getFirst();
        assertThat(granted).isEqualTo(50 + 90 + 50);

        var result = service.unmark(USER, s.id());
        assertThat(revoked).containsExactly(granted);
        assertThat(result.session().isCompleted()).isFalse();
        assertThat(result.session().xpAwarded()).isZero();
        assertThat(routine.day(day1.id()).status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        assertThat(events).hasSize(2);
        assertThat(events.get(1)).isInstanceOfSatisfying(TrainingSessionCompletionChanged.class, e -> {
            assertThat(e.completed()).isFalse();
            assertThat(e.rpe()).isEqualTo(10);
            assertThat(e.durationMinutes()).isEqualTo(120);
        });
        assertThatThrownBy(() -> service.unmark(USER, s.id())).isInstanceOf(SessionNotCompletedException.class);
    }

    @Test
    void unmarkKeepsDayCompletedIfAnotherSessionCompletedIt() {
        TrainingSession a = service.start(USER, routine.id(), day1.id());
        service.finish(new FinishTrainingSessionUseCase.Command(USER, a.id(), 1800, 6, null, null));
        TrainingSession b = service.start(USER, routine.id(), day1.id());
        service.finish(new FinishTrainingSessionUseCase.Command(USER, b.id(), 1800, 6, null, null));
        service.unmark(USER, b.id());
        assertThat(routine.day(day1.id()).status()).isEqualTo(ProgressStatus.COMPLETED);
    }

    @Test
    void cancelDeletesInProgressSessionAndResetsDay() {
        TrainingSession s = service.start(USER, routine.id(), day1.id());
        service.cancel(USER, s.id());
        assertThat(sessions.store).isEmpty();
        assertThat(routine.day(day1.id()).status()).isEqualTo(ProgressStatus.PENDING);
        TrainingSession done = service.start(USER, null, null);
        service.finish(new FinishTrainingSessionUseCase.Command(USER, done.id(), 600, 5, null, null));
        assertThatThrownBy(() -> service.cancel(USER, done.id())).isInstanceOf(SessionAlreadyCompletedException.class);
    }

    @Test
    void sessionsOfOtherUsersAreNotFound() {
        TrainingSession s = service.start(USER, null, null);
        assertThatThrownBy(() -> service.get(OTHER, s.id())).isInstanceOf(SessionNotFoundException.class);
        assertThatThrownBy(() -> service.unmark(OTHER, s.id())).isInstanceOf(SessionNotFoundException.class);
        assertThatThrownBy(() -> service.finish(new FinishTrainingSessionUseCase.Command(OTHER, s.id(), 600, 5, null, null)))
                .isInstanceOf(SessionNotFoundException.class);
    }

    @Test
    void setsMustReferToExercisesOfTheSessionRoutine() {
        TrainingSession free = service.start(USER, null, null);
        assertThatThrownBy(() -> service.recordSet(new RecordSessionSetUseCase.Command(USER, free.id(),
                planned(day1).id(), 1, 10, 20.0, true, 0))).isInstanceOf(RoutineExerciseNotFoundException.class);
        TrainingSession s = service.start(USER, routine.id(), day1.id());
        service.recordSet(new RecordSessionSetUseCase.Command(USER, s.id(), planned(day1).id(), 1, 10, 20.0, true, 0));
        TrainingSession replaced = service.recordSet(new RecordSessionSetUseCase.Command(USER, s.id(),
                planned(day1).id(), 1, 8, 20.0, true, 2));
        assertThat(replaced.sets()).singleElement().satisfies(x -> assertThat(x.failedReps()).isEqualTo(2));
    }

    @Test
    void freeSessionUsesDefaultMetAndDefaultWeight() {
        weight = null;
        TrainingSession s = service.start(USER, null, null);
        var result = service.finish(new FinishTrainingSessionUseCase.Command(USER, s.id(), 3600, 5, null, null));
        assertThat(result.session().calories()).isEqualTo(6.0 * 70);
        assertThat(result.recommendations()).isEmpty();
    }
}
