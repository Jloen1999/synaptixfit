package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.application.port.input.training.UpdateRoutineUseCase;
import com.synaptixfit.domain.exception.training.ExerciseInactiveException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineHasEmptyDaysException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineWeekLimitException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class RoutineServiceTest {

    private static final UUID OWNER = UUID.randomUUID();
    private static final UUID OTHER = UUID.randomUUID();
    private static final ExerciseParameters PARAMS = new ExerciseParameters(3, 10, 90, 40.0, null, null, null, null);

    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
    private RoutineService service;
    private Exercise bench;
    private Exercise row;

    @BeforeEach
    void setUp() {
        bench = exercises.add(TrainingFakes.strength("Press de banca", "Pectoral mayor"));
        row = exercises.add(TrainingFakes.strength("Remo con barra", "Dorsal ancho"));
        UserRepositoryPort users = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.empty(); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { return u; }
        };
        service = new RoutineService(routines, exercises, users,
                Clock.fixed(Instant.parse("2026-10-05T10:00:00Z"), ZoneOffset.UTC));
    }

    private Routine createTwoWeeks() {
        RoutineStructureInput.Day day1 = new RoutineStructureInput.Day(1, "Torso", List.of(
                new RoutineStructureInput.Exercise(bench.id(), PARAMS), new RoutineStructureInput.Exercise(row.id(), PARAMS)));
        RoutineStructureInput.Day day3 = new RoutineStructureInput.Day(3, null,
                List.of(new RoutineStructureInput.Exercise(row.id(), PARAMS)));
        return service.create(new CreateRoutineUseCase.Command(OWNER, "Fuerza base", null, Visibility.PUBLIC,
                TrainingGoal.MAX_STRENGTH, null, List.of(new RoutineStructureInput.Week(null, null, List.of(day1, day3)),
                new RoutineStructureInput.Week("Descarga", null, List.of()))));
    }

    @Test
    void createBuildsStructureWithDefaultsAndCount() {
        Routine r = createTwoWeeks();
        assertThat(r.exerciseCount()).isEqualTo(3);
        assertThat(r.durationWeeks()).isEqualTo(2);
        assertThat(r.weeks().get(0).type()).isEqualTo(WeekType.ADAPTATION);
        assertThat(r.weeks().get(0).name()).isEqualTo("Semana 1");
        assertThat(r.weeks().get(0).days().get(1).name()).isEqualTo("Día 3");
        assertThat(r.weeks().get(1).name()).isEqualTo("Descarga");
        assertThat(r.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(routines.store).containsKey(r.id());
    }

    @Test
    void createRejectsUnknownOrInactiveExercisesAndEmptyStructure() {
        UUID missing = UUID.randomUUID();
        assertThatThrownBy(() -> service.create(new CreateRoutineUseCase.Command(OWNER, "Mala", null, null, null, null,
                List.of(new RoutineStructureInput.Week(null, null, List.of(new RoutineStructureInput.Day(1, null,
                        List.of(new RoutineStructureInput.Exercise(missing, PARAMS)))))))))
                .isInstanceOf(ExerciseNotFoundException.class);
        exercises.setActive(bench.id(), false, Instant.now());
        assertThatThrownBy(() -> service.create(new CreateRoutineUseCase.Command(OWNER, "Mala", null, null, null, null,
                List.of(new RoutineStructureInput.Week(null, null, List.of(new RoutineStructureInput.Day(1, null,
                        List.of(new RoutineStructureInput.Exercise(bench.id(), PARAMS)))))))))
                .isInstanceOf(ExerciseInactiveException.class);
        assertThatThrownBy(() -> service.create(new CreateRoutineUseCase.Command(OWNER, "Vacía", null, null, null, null,
                List.of()))).isInstanceOf(RoutineWeekLimitException.class);
    }

    @Test
    void routinesOfOtherUsersAreNotFoundForEditing() {
        Routine r = createTwoWeeks();
        assertThatThrownBy(() -> service.update(new UpdateRoutineUseCase.Command(OTHER, r.id(), "Robada", null, null,
                null, null, false))).isInstanceOf(RoutineNotFoundException.class);
        assertThatThrownBy(() -> service.delete(OTHER, r.id())).isInstanceOf(RoutineNotFoundException.class);
        assertThatThrownBy(() -> service.addWeek(OTHER, r.id(), null, null)).isInstanceOf(RoutineNotFoundException.class);
        // Pero una rutina pública se puede ver.
        assertThat(service.get(OTHER, r.id()).routine().id()).isEqualTo(r.id());
    }

    @Test
    void privateRoutinesAreInvisibleToOthers() {
        Routine r = createTwoWeeks();
        service.update(new UpdateRoutineUseCase.Command(OWNER, r.id(), null, null, Visibility.PRIVATE, null, null, false));
        assertThatThrownBy(() -> service.get(OTHER, r.id())).isInstanceOf(RoutineNotFoundException.class);
        assertThatThrownBy(() -> service.cloneRoutine(OTHER, r.id())).isInstanceOf(RoutineNotFoundException.class);
    }

    @Test
    void cloneCopiesStructureWithOriginAndResetsProgress() {
        Routine r = createTwoWeeks();
        UUID day1 = r.weeks().getFirst().days().getFirst().id();
        r.startDay(day1, java.time.LocalDate.now());
        r.completeDay(day1);
        routines.authors.put(OWNER, "Ana");

        Routine copy = service.cloneRoutine(OTHER, r.id());
        assertThat(copy.ownerId()).isEqualTo(OTHER);
        assertThat(copy.id()).isNotEqualTo(r.id());
        assertThat(copy.name()).isEqualTo("Fuerza base (copiada)");
        assertThat(copy.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(copy.origin().routineId()).isEqualTo(r.id());
        assertThat(copy.origin().ownerName()).isEqualTo("Ana");
        assertThat(copy.completedDays()).isZero();
        assertThat(copy.exerciseCount()).isEqualTo(3);
        assertThat(copy.allDays().getFirst().id()).isNotEqualTo(day1);
    }

    @Test
    void duplicateKeepsOwnerAndUsesGivenName() {
        Routine r = createTwoWeeks();
        Routine copy = service.duplicate(OWNER, r.id(), "Copia de fuerza");
        assertThat(copy.ownerId()).isEqualTo(OWNER);
        assertThat(copy.name()).isEqualTo("Copia de fuerza");
        assertThat(copy.origin()).isNull();
    }

    @Test
    void completingRequiresNoEmptyDaysAndStructureChangesReactivate() {
        Routine r = createTwoWeeks();
        UUID week2 = r.weeks().get(1).id();
        service.addDay(OWNER, r.id(), week2, 2, null);
        assertThatThrownBy(() -> service.changeStatus(OWNER, r.id(), RoutineStatus.COMPLETED))
                .isInstanceOf(RoutineHasEmptyDaysException.class);
        UUID emptyDay = routines.store.get(r.id()).weeks().get(1).days().getFirst().id();
        service.addExercise(OWNER, r.id(), emptyDay, bench.id(), PARAMS);
        assertThat(service.changeStatus(OWNER, r.id(), RoutineStatus.COMPLETED).status()).isEqualTo(RoutineStatus.COMPLETED);
        Routine reactivated = service.addExercise(OWNER, r.id(), emptyDay, row.id(), PARAMS);
        assertThat(reactivated.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(reactivated.exerciseCount()).isEqualTo(5);
    }

    @Test
    void deletingAWeekRenumbersTheFollowingOnes() {
        Routine r = createTwoWeeks();
        service.addWeek(OWNER, r.id(), null, null);
        Routine after = service.deleteWeek(OWNER, r.id(), r.weeks().get(1).id());
        assertThat(after.weeks()).extracting(w -> w.number()).containsExactly(1, 2);
        assertThat(after.weeks().get(1).name()).isEqualTo("Semana 2");
        Routine single = service.deleteWeek(OWNER, r.id(), after.weeks().get(1).id());
        assertThatThrownBy(() -> service.deleteWeek(OWNER, r.id(), single.weeks().getFirst().id()))
                .isInstanceOf(RoutineWeekLimitException.class);
    }

    @Test
    void pendingDayIsFirstNotCompletedOfLatestActiveRoutine() {
        Routine r = createTwoWeeks();
        UUID day1 = r.weeks().getFirst().days().getFirst().id();
        assertThat(service.pendingDay(OWNER)).get().extracting(p -> p.day().id()).isEqualTo(day1);
        r.completeDay(day1);
        assertThat(service.pendingDay(OWNER).orElseThrow().day().number()).isEqualTo(3);
        assertThat(service.pendingDay(OTHER)).isEmpty();
    }

    @Test
    void privatizeAllOnlySavesRoutinesThatChange() {
        createTwoWeeks();
        createTwoWeeks();
        int savesBefore = routines.saves;
        assertThat(service.privatizeAll(OWNER)).isEqualTo(2);
        assertThat(routines.saves - savesBefore).isEqualTo(2);
        assertThat(service.privatizeAll(OWNER)).isZero();
        assertThat(service.listMine(OWNER, null, new PageRequest(0, 10)).items())
                .allMatch(r -> r.visibility() == Visibility.PRIVATE);
    }

    @Test
    void reorderAndUpdateExercise() {
        Routine r = createTwoWeeks();
        var day = r.weeks().getFirst().days().getFirst();
        UUID first = day.exercises().get(0).id();
        UUID second = day.exercises().get(1).id();
        Routine reordered = service.reorder(OWNER, r.id(), day.id(), List.of(second, first));
        assertThat(reordered.day(day.id()).exercises()).extracting(e -> e.id()).containsExactly(second, first);
        assertThat(reordered.day(day.id()).exercises()).extracting(e -> e.order()).containsExactly(1, 2);
        Routine updated = service.updateExercise(OWNER, r.id(), first, new ExerciseParameters(5, 5, 180, 60.0, null, null, null, null));
        assertThat(updated.plannedExercise(first).parameters().sets()).isEqualTo(5);
        assertThat(updated.day(day.id()).status()).isEqualTo(ProgressStatus.PENDING);
    }
}
