package com.synaptixfit.domain.model.training.load;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Calibración de la primera sesión (ADR 0054) y escalones de peso por material. */
class ExerciseCalibrationTest {

    private static final Instant NOW = Instant.parse("2026-11-16T10:00:00Z");
    private static final LoadProfile SQUAT = new LoadProfile(LoadType.BARBELL, 0.35, 20.0, 60.0, true);
    private static final LoadProfile BENCH = new LoadProfile(LoadType.BARBELL, 0.25, 20.0, 40.0, false);
    private static final LoadProfile DUMBBELLS = new LoadProfile(LoadType.DUMBBELL_PAIR, 0.08, 6.0, 16.0, false);
    private static final LoadProfile KETTLEBELL = new LoadProfile(LoadType.KETTLEBELL, 0.15, 8.0, 16.0, true);
    private static final LoadProfile MACHINE = new LoadProfile(LoadType.MACHINE, null, null, null, false);
    private static final LoadProfile BODYWEIGHT = new LoadProfile(LoadType.BODYWEIGHT, null, null, null, false);

    @Test
    void fourOrMoreLeftGoesUpOneStepOfTheMaterial() {
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, 40.0, SQUAT)).isEqualTo(up(45.0));
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, 20.0, BENCH)).isEqualTo(up(22.5));
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, 6.0, DUMBBELLS)).isEqualTo(up(8.0));
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, 12.0, KETTLEBELL)).isEqualTo(up(16.0));
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, 30.0, MACHINE)).isEqualTo(up(35.0));
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, 10.0, null)).isEqualTo(up(12.5));
    }

    @Test
    void threeOrOneTwoKeepsTheWeight() {
        assertThat(adjust(CalibrationAnswer.THREE, 40.0, SQUAT))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.KEEP, 40.0));
        assertThat(adjust(CalibrationAnswer.ONE_TWO, 8.0, DUMBBELLS))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.KEEP, 8.0));
    }

    @Test
    void noneOrMissedRepsGoesDownButNeverBelowTheMaterialMinimum() {
        assertThat(adjust(CalibrationAnswer.NONE, 30.0, SQUAT))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.DOWN, 25.0));
        assertThat(ExerciseCalibration.adjust(CalibrationAnswer.FOUR_PLUS, 8.0, DUMBBELLS, true))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.DOWN, 6.0));
        assertThat(adjust(CalibrationAnswer.NONE, 12.0, KETTLEBELL))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.DOWN, 10.0));
        // Barra vacía y la mancuerna más ligera: no hay escalón al que bajar.
        assertThat(adjust(CalibrationAnswer.NONE, 20.0, BENCH))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.KEEP, 20.0));
        assertThat(adjust(CalibrationAnswer.NONE, 2.0, DUMBBELLS))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.KEEP, 2.0));
    }

    @Test
    void withoutKilosOnlyTheStepIsSaidAndBodyweightNeverChanges() {
        assertThat(adjust(CalibrationAnswer.FOUR_PLUS, null, MACHINE))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.UP, null));
        assertThat(adjust(CalibrationAnswer.NONE, null, BODYWEIGHT))
                .isEqualTo(new ExerciseCalibration.Result(CalibrationStep.KEEP, null));
    }

    @Test
    void onlyWeightedRepExercisesWithoutRecentHistoryAreCalibrated() {
        ExerciseRef squat = ref(SQUAT, MeasurementType.REPETITIONS, MeasurementType.WEIGHT);
        ExerciseRef pushUp = ref(BODYWEIGHT, MeasurementType.REPETITIONS, MeasurementType.WEIGHT);
        ExerciseRef plank = ref(null, MeasurementType.TIME);

        assertThat(ExerciseCalibration.needed(squat, List.of(), NOW)).isTrue();
        assertThat(ExerciseCalibration.needed(pushUp, List.of(), NOW)).isFalse();
        assertThat(ExerciseCalibration.needed(plank, List.of(), NOW)).isFalse();

        CompletedSessionSummary lastWeek = new CompletedSessionSummary(UUID.randomUUID(),
                NOW.minus(Duration.ofDays(7)), 7, 40, List.of(new PerformedSet(squat.id(), "Sentadilla",
                new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, 8, 40.0, true, 0, null, null, squat.id()))));
        assertThat(ExerciseCalibration.needed(squat, List.of(lastWeek), NOW)).isFalse();
    }

    @Test
    void loadStepsRoundDownToRealMaterial() {
        assertThat(LoadStep.floor(27.9, SQUAT)).isEqualTo(27.5);
        assertThat(LoadStep.floor(12.0, SQUAT)).isEqualTo(20.0);
        assertThat(LoadStep.floor(7.9, DUMBBELLS)).isEqualTo(6.0);
        assertThat(LoadStep.floor(15.0, KETTLEBELL)).isEqualTo(12.0);
        assertThat(LoadStep.reduce(50.0, 10, SQUAT)).isEqualTo(45.0);
        assertThat(LoadStep.reduce(21.0, 10, BENCH)).isEqualTo(20.0);
        assertThat(LoadStep.down(4.0, KETTLEBELL)).isEqualTo(4.0);
        assertThat(LoadStep.up(32.0, KETTLEBELL)).isEqualTo(32.0);
    }

    private static ExerciseCalibration.Result adjust(CalibrationAnswer answer, Double kg, LoadProfile profile) {
        return ExerciseCalibration.adjust(answer, kg, profile, false);
    }

    private static ExerciseCalibration.Result up(double kg) {
        return new ExerciseCalibration.Result(CalibrationStep.UP, kg);
    }

    private static ExerciseRef ref(LoadProfile load, MeasurementType... types) {
        return new ExerciseRef(UUID.randomUUID(), "Ejercicio", null, null, Modality.STRENGTH, List.of(types), false,
                5.0, true, load);
    }
}
