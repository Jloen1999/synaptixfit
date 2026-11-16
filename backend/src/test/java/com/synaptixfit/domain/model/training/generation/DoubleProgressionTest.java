package com.synaptixfit.domain.model.training.generation;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.RepRange;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.load.LoadProfile;
import com.synaptixfit.domain.model.training.load.LoadType;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/**
 * Doble progresión con el rango del ejercicio (ADR 0054): al tope del rango con el esfuerzo pedido sube un escalón
 * del material y vuelve al mínimo; si no, +1 repetición; dos sesiones sin llegar al mínimo, −10 %. El peso es el
 * mismo en todas las series (sin rampa 50/75/100 %).
 */
class DoubleProgressionTest {

    private static final List<MeasurementType> WEIGHTED = List.of(MeasurementType.REPETITIONS,
            MeasurementType.WEIGHT);
    private static final LoadProfile SQUAT = new LoadProfile(LoadType.BARBELL, 0.35, 20.0, 60.0, true);
    private static final LoadProfile BENCH = new LoadProfile(LoadType.BARBELL, 0.25, 20.0, 40.0, false);
    private static final LoadProfile DUMBBELLS = new LoadProfile(LoadType.DUMBBELL_PAIR, 0.08, 6.0, 16.0, false);
    private static final RepRange EIGHT_TWELVE = new RepRange(8, 12, 2);

    @Test
    void allSetsAtTheTopWithTheRightEffortAddAMaterialStepAndGoBackToTheMinimum() {
        ProgressionCalculator.Result squat = progress(params(12, 40.0), 8, SQUAT, false, 12, 12, 12);
        assertThat(squat.reason()).isEqualTo(AdjustmentReason.LOW_RPE_MORE_WEIGHT);
        assertThat(squat.parameters().weightKg()).isEqualTo(45.0);
        assertThat(squat.parameters().reps()).isEqualTo(8);
        assertThat(squat.parameters().weightsKg()).isNull();
        assertThat(squat.parameters().repRange()).isEqualTo(EIGHT_TWELVE);
        assertThat(squat.parameters().sets()).isEqualTo(3);

        assertThat(progress(params(12, 40.0), 8, BENCH, false, 12, 12, 12).parameters().weightKg()).isEqualTo(42.5);
        assertThat(progress(params(12, 8.0), 8, DUMBBELLS, false, 12, 12, 12).parameters().weightKg()).isEqualTo(10.0);
    }

    @Test
    void tooMuchEffortAtTheTopKeepsEverything() {
        ProgressionCalculator.Result r = progress(params(12, 40.0), 9, SQUAT, false, 12, 12, 12);
        assertThat(r.reason()).isNull();
        assertThat(r.parameters()).isEqualTo(params(12, 40.0));
    }

    @Test
    void insideTheRangeAddsOneRep() {
        ProgressionCalculator.Result r = progress(params(9, 40.0), 7, SQUAT, false, 9, 10, 9);
        assertThat(r.reason()).isEqualTo(AdjustmentReason.LOW_RPE_MORE_REPS);
        assertThat(r.parameters().reps()).isEqualTo(10);
        assertThat(r.parameters().weightKg()).isEqualTo(40.0);
    }

    @Test
    void belowTheMinimumOnceRepeatsAndTwiceInARowDropsTenPercent() {
        ProgressionCalculator.Result once = progress(params(8, 50.0), 9, SQUAT, false, 8, 7, 6);
        assertThat(once.reason()).isNull();
        assertThat(once.parameters().weightKg()).isEqualTo(50.0);

        ProgressionCalculator.Result twice = progress(params(8, 50.0), 9, SQUAT, true, 8, 7, 6);
        assertThat(twice.reason()).isEqualTo(AdjustmentReason.FAILED_REPS);
        assertThat(twice.parameters().weightKg()).isEqualTo(45.0);
        assertThat(twice.parameters().reps()).isEqualTo(8);
        assertThat(twice.parameters().sets()).isEqualTo(3);
    }

    @Test
    void withoutARangeTheOldRulesUseAMaterialStepInsteadOfFivePercentAndNoRamp() {
        ExerciseParameters plain = new ExerciseParameters(3, 15, 90, 40.0, null, null, null, null);
        ProgressionCalculator.Result r = ProgressionCalculator.progress(plain, WEIGHTED, 6, sets(15, 15, 15),
                GoalParameters.of(com.synaptixfit.domain.model.training.TrainingGoal.HYPERTROPHY), BENCH, false);
        assertThat(r.reason()).isEqualTo(AdjustmentReason.LOW_RPE_MORE_WEIGHT);
        assertThat(r.parameters().weightKg()).isEqualTo(42.5);
        assertThat(r.parameters().weightsKg()).isNull();
    }

    private static ExerciseParameters params(int reps, double kg) {
        return new ExerciseParameters(3, reps, 120, kg, null, null, null, null, null, null, EIGHT_TWELVE);
    }

    private static ProgressionCalculator.Result progress(ExerciseParameters p, double rpe, LoadProfile load,
                                                         boolean belowMinLastTime, int... reps) {
        return ProgressionCalculator.progress(p, WEIGHTED, rpe, sets(reps), null, load, belowMinLastTime);
    }

    private static List<SessionSet> sets(int... reps) {
        return IntStream.range(0, reps.length).mapToObj(i -> new SessionSet(UUID.randomUUID(), UUID.randomUUID(),
                i + 1, reps[i], 40.0, true, 0, null, null, null)).toList();
    }
}
