package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Duración prevista (ADR 0048): la base es series × (trabajo + descanso); con datos reales aprende de las tres
 * últimas veces, cada una acotada a [0,5 × base, 2,5 × base] (1 → esa, 2 → media, 3 → mediana).
 */
class SessionDurationEstimateTest {

    /** 4 series × (10 reps × 3 s + 90 s) = 480 s; acotado a [240, 1200]. */
    private static final ExerciseParameters BENCH = new ExerciseParameters(4, 10, 90, 40.0, null, null, null, null);

    @Test
    void repetitionsUseThreeSecondsPerRepPlusRest() {
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of())).isEqualTo(480);
        assertThat(SessionDurationEstimate.learnedSeconds(BENCH, null)).isNull();
    }

    @Test
    void timedAndIsometricExercisesUseTheirTime() {
        ExerciseParameters run = new ExerciseParameters(1, 1, 60, null, null, 1500, 5000, null);
        assertThat(SessionDurationEstimate.exerciseSeconds(run, null)).isEqualTo(1560);
        ExerciseParameters plank = new ExerciseParameters(3, 1, 45, null, null, null, null, 30);
        assertThat(SessionDurationEstimate.exerciseSeconds(plank, null)).isEqualTo(225);
    }

    @Test
    void oneRealDurationIsUsedAsItIs() {
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of(600))).isEqualTo(600);
    }

    @Test
    void twoRealDurationsUseTheirMean() {
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of(500, 601))).isEqualTo(551);
    }

    @Test
    void threeRealDurationsUseTheMedianSoAnOddDayDoesNotCount() {
        // Un día de 1100 s (se charló entre series) no mueve la estimación: manda la mediana.
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of(520, 1100, 540))).isEqualTo(540);
    }

    @Test
    void eachRealDurationIsBoundedByTheBase() {
        // Una sesión olvidada abierta (3 h) cuenta como 2,5 × base; marcarlo todo de golpe, como 0,5 × base.
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of(10_800))).isEqualTo(1200);
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of(30))).isEqualTo(240);
        assertThat(SessionDurationEstimate.exerciseSeconds(BENCH, List.of(10_800, 30))).isEqualTo(720);
    }

    @Test
    void onlyTheLastThreeRunsAreRemembered() {
        UUID id = UUID.randomUUID();
        ExerciseRef ref = ExerciseRef.unknown(UUID.randomUUID());
        Instant t = Instant.parse("2026-11-01T10:00:00Z");
        PlannedExercise bench = new PlannedExercise(id, ref, BENCH, 1, null);
        assertThat(bench.realDurationSeconds()).isNull();
        assertThat(bench.estimatedSeconds()).isEqualTo(480);

        bench.recordRealDuration(900, t);
        bench.recordRealDuration(500, t.plusSeconds(86_400));
        bench.recordRealDuration(520, t.plusSeconds(2 * 86_400));
        bench.recordRealDuration(540, t.plusSeconds(3 * 86_400));
        bench.recordRealDuration(0, t.plusSeconds(4 * 86_400));

        assertThat(bench.recentDurations()).extracting(RecordedDuration::seconds).containsExactly(500, 520, 540);
        assertThat(bench.realDurationSeconds()).isEqualTo(520);
        assertThat(bench.estimatedSeconds()).isEqualTo(520);
    }
}
