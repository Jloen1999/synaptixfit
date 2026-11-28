package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.FinishTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.application.port.input.training.StartFreeSessionUseCase;
import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TemplatePlace;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
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
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Sesión libre con ejercicios (ADR 0067): lista al empezar, «Añadir ejercicio», repetir, plantilla y guardar. */
class FreeSessionServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-26T18:00:00Z");

    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
    private final List<DomainEvent> events = new ArrayList<>();
    private final List<Integer> awarded = new ArrayList<>();
    private final AtomicReference<CreateRoutineUseCase.Command> created = new AtomicReference<>();
    private Instant now = NOW;
    private final Clock clock = new Clock() {
        public java.time.ZoneId getZone() { return ZoneOffset.UTC; }
        public Clock withZone(java.time.ZoneId zone) { return this; }
        public Instant instant() { return now; }
    };
    private Exercise squat;
    private Exercise plank;
    private RoutineTemplate template;
    private FreeSessionService free;
    private TrainingSessionService service;

    @BeforeEach
    void setUp() {
        squat = exercises.add(TrainingFakes.strength("Sentadilla", "Cuádriceps"));
        plank = exercises.add(TrainingFakes.exercise("Plancha", Modality.STRENGTH, List.of(MeasurementType.TIME),
                List.of("Core"), List.of(), TrainingGoal.HYPERTROPHY));
        template = new RoutineTemplate(UUID.randomUUID(), "casa", "En casa", "", TrainingGoal.HYPERTROPHY,
                TemplatePlace.HOME, TemplateLevel.BEGINNER, false, 30, 4,
                List.of(new RoutineTemplate.Day(3, List.of(new RoutineTemplate.Item(squat.id(), 4, 8, 120, null)))),
                List.of());
        RoutineTemplateRepositoryPort templates = new RoutineTemplateRepositoryPort() {
            public List<RoutineTemplate> findAll(String language) { return List.of(template); }
            public Optional<RoutineTemplate> findById(UUID id, String language) {
                return Optional.of(template).filter(t -> t.id().equals(id));
            }
        };
        free = new FreeSessionService(sessions, routines, exercises, templates,
                (userId, ids, level) -> Map.of(squat.id(), 40.0), command -> {
                    created.set(command);
                    return null;
                }, clock, ZoneOffset.UTC);
        TrainingContextPort context = new TrainingContextPort() {
            public Optional<Double> bodyWeightKg(UUID userId) { return Optional.of(70.0); }
            public Optional<com.synaptixfit.domain.model.training.generation.TrainingProfile> profile(UUID u) {
                return Optional.empty();
            }
            public AcademicContext academicContext(UUID userId, LocalDate today) { return AcademicContext.NONE; }
            public PhysiologicalContext physiologicalContext(UUID userId, LocalDate today) {
                return PhysiologicalContext.NONE;
            }
            public Optional<GoalChange> latestGoalChange(UUID userId) { return Optional.empty(); }
        };
        service = new TrainingSessionService(sessions, routines, exercises, new TrainingFakes.Recommendations(),
                context, (userId, amount) -> {
                    awarded.add(amount);
                    return new ExperienceChange(1, amount, 0, amount);
                }, (userId, amount) -> new ExperienceChange(1, 0, 0, -amount), events::add, clock, ZoneOffset.UTC);
    }

    private TrainingSession startWith(List<UUID> ids) {
        return free.startFree(new StartFreeSessionUseCase.Command(USER, ids, null, null, null, "es"));
    }

    @Test
    void startsWithTheChosenExercisesAndTheirStartingFigures() {
        TrainingSession s = startWith(List.of(squat.id(), plank.id(), squat.id()));

        assertThat(s.dayId()).isNull();
        assertThat(s.freeExercises()).extracting(PlannedExercise::exerciseId).containsExactly(squat.id(), plank.id());
        assertThat(s.freeExercises().get(0).parameters().weightKg()).isEqualTo(40.0);
        assertThat(s.freeExercises().get(1).parameters().isometricSeconds()).isEqualTo(30);
    }

    @Test
    void eachSetKeepsItsExerciseAndTheSessionCountsLikeAnyOther() {
        TrainingSession s = startWith(List.of(squat.id(), plank.id()));
        UUID slot = s.freeExercises().getFirst().id();
        service.recordSet(new RecordSessionSetUseCase.Command(USER, s.id(), slot, 1, 8, 40.0, true, null));
        service.recordSet(new RecordSessionSetUseCase.Command(USER, s.id(), s.freeExercises().get(1).id(), 1,
                null, null, true, null, 30, null));

        assertThat(sessions.store.get(s.id()).sets()).extracting(x -> x.exerciseId())
                .containsExactlyInAnyOrder(squat.id(), plank.id());

        now = NOW.plusSeconds(1800);
        FinishTrainingSessionUseCase.Result result = service.finish(new FinishTrainingSessionUseCase.Command(USER,
                s.id(), 1800, 7, null, null));
        assertThat(result.session().isCompleted()).isTrue();
        assertThat(awarded).hasSize(1).allMatch(xp -> xp > 0);
        assertThat(events).anyMatch(e -> e instanceof TrainingSessionCompletionChanged c && c.completed());
    }

    @Test
    void addsAnExerciseOnTheGoOnlyOnce() {
        TrainingSession s = startWith(List.of());

        free.addExercise(USER, s.id(), squat.id());
        TrainingSession again = free.addExercise(USER, s.id(), squat.id());

        assertThat(again.freeExercises()).hasSize(1);
    }

    @Test
    void aRoutineSessionDoesNotTakeExtraExercises() {
        TrainingSession routineSession = sessions.save(TrainingSession.start(USER, UUID.randomUUID(),
                UUID.randomUUID(), NOW));

        assertThatThrownBy(() -> free.addExercise(USER, routineSession.id(), squat.id()))
                .isInstanceOf(DomainException.class).extracting("code").isEqualTo("SESSION_NOT_FREE");
    }

    @Test
    void repeatsWhatWasDoneInAPreviousSession() {
        TrainingSession before = startWith(List.of(squat.id(), plank.id()));
        UUID slot = before.freeExercises().getFirst().id();
        service.recordSet(new RecordSessionSetUseCase.Command(USER, before.id(), slot, 1, 8, 50.0, true, null));
        service.recordSet(new RecordSessionSetUseCase.Command(USER, before.id(), slot, 2, 6, 55.0, true, null));

        TrainingSession again = free.startFree(new StartFreeSessionUseCase.Command(USER, null, before.id(), null,
                null, "es"));

        assertThat(again.freeExercises()).singleElement().satisfies(p -> {
            assertThat(p.exerciseId()).isEqualTo(squat.id());
            assertThat(p.parameters().sets()).isEqualTo(2);
            assertThat(p.parameters().weightKg()).isEqualTo(55.0);
        });
    }

    @Test
    void anOldFreeSessionWithoutExercisesCannotBeRepeated() {
        TrainingSession old = sessions.save(TrainingSession.start(USER, null, null, NOW));
        old.recordSet(null, 1, 10, 20.0, true, 0);

        assertThatThrownBy(() -> free.startFree(new StartFreeSessionUseCase.Command(USER, null, old.id(), null, null,
                "es"))).isInstanceOf(DomainException.class).extracting("code")
                .isEqualTo("SESSION_NOTHING_TO_REPEAT");
    }

    @Test
    void startsFromATemplateDayWithItsFirstWeekFigures() {
        TrainingSession s = free.startFree(new StartFreeSessionUseCase.Command(USER, null, null, template.id(), 3,
                "es"));

        assertThat(s.freeExercises()).singleElement().satisfies(p -> {
            assertThat(p.parameters().sets()).isEqualTo(4);
            assertThat(p.parameters().weightKg()).isEqualTo(40.0);
        });
    }

    @Test
    void savesWhatWasDoneAsAOneDayRoutine() {
        TrainingSession s = startWith(List.of(squat.id(), plank.id()));
        service.recordSet(new RecordSessionSetUseCase.Command(USER, s.id(), s.freeExercises().getFirst().id(), 1, 8,
                40.0, true, null));

        free.saveAsRoutine(USER, s.id(), "Pierna del jueves");

        CreateRoutineUseCase.Command c = created.get();
        assertThat(c.name()).isEqualTo("Pierna del jueves");
        assertThat(c.weeks()).singleElement().satisfies(w -> assertThat(w.days()).singleElement().satisfies(d -> {
            assertThat(d.dayNumber()).isEqualTo(4);
            assertThat(d.exercises()).extracting(e -> e.exerciseId()).containsExactly(squat.id());
        }));
    }

    @Test
    void nothingDoneIsNothingToSave() {
        TrainingSession s = startWith(List.of(squat.id()));

        assertThatThrownBy(() -> free.saveAsRoutine(USER, s.id(), "Vacía")).isInstanceOf(DomainException.class)
                .extracting("code").isEqualTo("SESSION_NOTHING_TO_SAVE");
    }
}
