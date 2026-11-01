package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.generation.GoalParameters;
import com.synaptixfit.domain.model.training.generation.ProgressionCalculator;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Objetivos por serie (ADR 0027), sustitución de ejercicios, portada de la rutina y series de tiempo/distancia. */
class PerSetTargetsTest {

    private static final ExerciseRef BENCH = ref("Press banca", List.of(MeasurementType.REPETITIONS,
            MeasurementType.WEIGHT));
    private static final ExerciseRef PUSH_UP = ref("Flexiones", List.of(MeasurementType.REPETITIONS));
    private static final ExerciseRef PLANK = ref("Plancha", List.of(MeasurementType.TIME));
    private static final ExerciseRef RUN = new ExerciseRef(UUID.randomUUID(), "Correr", null, null, Modality.AEROBIC,
            List.of(MeasurementType.TIME), false, 8.0, true);

    private static ExerciseRef ref(String name, List<MeasurementType> types) {
        return new ExerciseRef(UUID.randomUUID(), name, null, "https://media/" + name, Modality.STRENGTH, types,
                false, 6.0, true);
    }

    private static ExerciseParameters perSet(List<Integer> reps) {
        return new ExerciseParameters(3, 10, 90, 40.0, List.of(30.0, 40.0), null, null, null, reps, null);
    }

    @Test
    void eachSetUsesItsOwnValueAndFallsBackToTheCommonOne() {
        ExerciseParameters p = perSet(List.of(12, 10));

        assertThat(p.repsForSet(1)).isEqualTo(12);
        assertThat(p.repsForSet(2)).isEqualTo(10);
        assertThat(p.repsForSet(3)).isEqualTo(10);
        assertThat(p.weightForSet(1)).isEqualTo(30.0);
        assertThat(p.weightForSet(3)).isEqualTo(40.0);
        assertThat(new ExerciseParameters(3, 8, 90, null, null, null, null, null).repsPerSet()).isNull();
    }

    @Test
    void theServerDerivesTheCommonValueFromCompleteLists() {
        // El cliente manda un común que no cuadra: manda la regla del dominio.
        ExerciseParameters p = new ExerciseParameters(3, 50, 90, 10.0, List.of(30.0, 35.0, 40.0), null, null, null,
                List.of(12, 10, 8, 6), null);

        assertThat(p.repsPerSet()).containsExactly(12, 10, 8);
        assertThat(p.reps()).isEqualTo(10);
        assertThat(p.weightKg()).isEqualTo(40.0);
        ExerciseParameters same = new ExerciseParameters(2, 9, 90, null, null, null, null, null, List.of(8, 8), null);
        assertThat(same.repsPerSet()).isNull();
        assertThat(same.reps()).isEqualTo(8);
    }

    @Test
    void perSetValuesAreValidated() {
        assertThatThrownBy(() -> perSet(List.of(12, 0))).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> perSet(List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> perSet(Arrays.asList(12, null))).isInstanceOf(FieldValidationException.class);
        assertThat(perSet(List.of()).repsPerSet()).isNull();
    }

    @Test
    void progressionMovesEveryPerSetRepetition() {
        ExerciseParameters p = perSet(List.of(12, 10, 8));

        ExerciseParameters next = ProgressionCalculator.progress(p, BENCH.measurementTypes(), 6, List.of(),
                GoalParameters.of(TrainingGoal.HYPERTROPHY)).parameters();

        assertThat(next.reps()).isEqualTo(11);
        assertThat(next.repsPerSet()).containsExactly(13, 11, 9);
    }

    @Test
    void trackingKindFollowsTheCatalogAndThePlannedData() {
        assertThat(BENCH.trackingKind()).isEqualTo(TrackingKind.REPETITIONS);
        assertThat(PLANK.trackingKind()).isEqualTo(TrackingKind.HOLD);
        assertThat(RUN.trackingKind()).isEqualTo(TrackingKind.CARDIO);
        PlannedExercise legacyRun = new PlannedExercise(UUID.randomUUID(), RUN,
                new ExerciseParameters(3, 1, 60, null, null, null, null, 45), 1, null);
        assertThat(legacyRun.trackingKind()).isEqualTo(TrackingKind.HOLD);
    }

    @Test
    void replacingCardioWithStrengthDropsTimeAndDistance() {
        ExerciseParameters run = new ExerciseParameters(1, 1, 60, null, null, 1500, 5000, null);

        ExerciseParameters bench = run.adaptedTo(BENCH);

        assertThat(bench.targetDurationSeconds()).isNull();
        assertThat(bench.distanceMeters()).isNull();
        assertThat(bench.isometricSeconds()).isNull();
    }

    @Test
    void replacingStrengthWithAnAerobicExerciseGivesACardioBlock() {
        ExerciseParameters cardio = perSet(List.of(12, 10, 8)).adaptedTo(RUN);

        assertThat(cardio.targetDurationSeconds()).isEqualTo(ExerciseParameters.DEFAULT_CARDIO_SECONDS);
        assertThat(cardio.isometricSeconds()).isNull();
        assertThat(cardio.weightKg()).isNull();
        assertThat(cardio.repsPerSet()).isNull();
    }

    @Test
    void replacingKeepsThePositionAndAdaptsTheParametersToTheNewExercise() {
        RoutineDay day = RoutineDay.create(1, null);
        PlannedExercise first = day.addExercise(BENCH, perSet(List.of(12, 10, 8)));
        day.addExercise(PUSH_UP, new ExerciseParameters(3, 15, 60, null, null, null, null, null));

        PlannedExercise replaced = day.replaceExercise(first.id(), PLANK);

        assertThat(replaced.id()).isNotEqualTo(first.id());
        assertThat(day.exercises().getFirst().id()).isEqualTo(replaced.id());
        assertThat(replaced.order()).isEqualTo(1);
        assertThat(replaced.parameters().weightKg()).isNull();
        assertThat(replaced.parameters().weightsKg()).isNull();
        assertThat(replaced.parameters().isometricSeconds()).isEqualTo(30);
        assertThat(replaced.parameters().sets()).isEqualTo(3);
    }

    @Test
    void theCoverIsTheFirstExerciseOfTheDayThatIsDue() {
        RoutineDay monday = RoutineDay.create(1, null);
        monday.addExercise(BENCH, perSet(null));
        RoutineDay thursday = RoutineDay.create(4, null);
        thursday.addExercise(PLANK, new ExerciseParameters(3, 1, 60, null, null, null, null, 30));
        Routine routine = Routine.create(UUID.randomUUID(), "Rutina", null, Visibility.PRIVATE,
                TrainingGoal.HYPERTROPHY, null, null, List.of(RoutineWeek.create(1, null, null,
                        List.of(monday, thursday))), Instant.parse("2026-11-01T10:00:00Z"));

        assertThat(routine.coverExercise()).contains(BENCH);
        routine.completeDay(monday.id(), LocalDate.of(2026, 11, 2));
        assertThat(routine.coverExercise()).contains(PLANK);
    }

    @Test
    void aSetCanRecordTimeAndDistance() {
        TrainingSession session = TrainingSession.start(UUID.randomUUID(), null, null,
                Instant.parse("2026-11-01T10:00:00Z"));

        SessionSet set = session.recordSet(null, null, 1, null, null, true, 0, 1_500, 5_000);

        assertThat(set.durationSeconds()).isEqualTo(1_500);
        assertThat(set.distanceMeters()).isEqualTo(5_000);
        assertThatThrownBy(() -> session.recordSet(null, null, 2, null, null, true, 0, 20_000, null))
                .isInstanceOf(FieldValidationException.class);
    }
}
