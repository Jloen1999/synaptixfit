package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/** Duración prevista: la real si ya se hizo; si no, series × (trabajo + descanso). */
class SessionDurationEstimateTest {

    @Test
    void repetitionsUseThreeSecondsPerRepPlusRest() {
        // 4 series × (10 reps × 3 s + 90 s) = 480 s.
        ExerciseParameters bench = new ExerciseParameters(4, 10, 90, 40.0, null, null, null, null);
        assertThat(SessionDurationEstimate.exerciseSeconds(bench, null)).isEqualTo(480);
    }

    @Test
    void timedAndIsometricExercisesUseTheirTime() {
        ExerciseParameters run = new ExerciseParameters(1, 1, 60, null, null, 1500, 5000, null);
        assertThat(SessionDurationEstimate.exerciseSeconds(run, null)).isEqualTo(1560);
        ExerciseParameters plank = new ExerciseParameters(3, 1, 45, null, null, null, null, 30);
        assertThat(SessionDurationEstimate.exerciseSeconds(plank, null)).isEqualTo(225);
    }

    @Test
    void theRealDurationOfLastTimeWins() {
        ExerciseParameters bench = new ExerciseParameters(4, 10, 90, 40.0, null, null, null, null);
        assertThat(SessionDurationEstimate.exerciseSeconds(bench, 600)).isEqualTo(600);
    }
}
