package com.synaptixfit.domain.model.training.generation;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import com.synaptixfit.domain.model.training.generation.LoadSuggestion.Metric;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Propuesta de carga dentro de la sesión («Hoy prueba 42 kg (+5 %)»), desde la última vez. */
class LoadSuggestionsTest {

    private static final Instant NOW = Instant.parse("2026-11-02T10:00:00Z");
    private static final GoalParameters HYPERTROPHY = GoalParameters.of(TrainingGoal.HYPERTROPHY);
    private static final ExerciseRef BENCH = new ExerciseRef(UUID.randomUUID(), "Press banca", null, null,
            Modality.STRENGTH, List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), false, 6.0, true);
    private static final ExerciseRef PLANK = new ExerciseRef(UUID.randomUUID(), "Plancha", null, null,
            Modality.STRENGTH, List.of(MeasurementType.TIME), false, 4.0, true);

    private static PlannedExercise bench(int reps, double kg) {
        return new PlannedExercise(UUID.randomUUID(), BENCH,
                new ExerciseParameters(3, reps, 90, kg, null, null, null, null), 1, null);
    }

    /** Sesión de hace {@code daysAgo} días con {@code sets} series iguales del ejercicio. */
    private static CompletedSessionSummary session(ExerciseRef ex, int daysAgo, int rpe, int sets, Integer reps,
                                                   Double kg, int failedPerSet, Integer seconds) {
        List<PerformedSet> performed = new ArrayList<>();
        for (int n = 1; n <= sets; n++) {
            performed.add(new PerformedSet(ex.id(), ex.name(), new SessionSet(UUID.randomUUID(), null, n, reps, kg,
                    failedPerSet == 0, failedPerSet, seconds, null, ex.id())));
        }
        return new CompletedSessionSummary(UUID.randomUUID(), NOW.minus(Duration.ofDays(daysAgo)), rpe, 40,
                performed);
    }

    @Test
    void atTheTopOfTheRepRangeWithLowEffortProposesFivePercentMoreWeight() {
        PlannedExercise p = bench(15, 40.0);

        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(p),
                List.of(session(BENCH, 3, 6, 3, 15, 40.0, 0, null)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> {
            assertThat(x.plannedExerciseId()).isEqualTo(p.id());
            assertThat(x.metric()).isEqualTo(Metric.WEIGHT);
            assertThat(x.previous()).isEqualTo(40.0);
            assertThat(x.suggested()).isEqualTo(42.0);
            assertThat(x.changePercent()).isEqualTo(5);
            assertThat(x.reason()).isEqualTo(AdjustmentReason.LOW_RPE_MORE_WEIGHT);
            assertThat(x.lastRpe()).isEqualTo(6);
            assertThat(x.increases()).isTrue();
        });
    }

    @Test
    void aPyramidMovesEachSetInTheSameProportion() {
        PlannedExercise pyramid = new PlannedExercise(UUID.randomUUID(), BENCH,
                new ExerciseParameters(3, 15, 90, 40.0, List.of(20.0, 30.0, 40.0), null, null, null), 1, null);

        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(pyramid),
                List.of(session(BENCH, 3, 6, 3, 15, 40.0, 0, null)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> assertThat(x.perSet()).containsExactly(21.0, 31.5, 42.0));
    }

    @Test
    void belowTheTopProposesOneMoreRep() {
        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(bench(10, 40.0)),
                List.of(session(BENCH, 2, 7, 3, 10, 40.0, 0, null)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> {
            assertThat(x.metric()).isEqualTo(Metric.REPS);
            assertThat(x.previous()).isEqualTo(10.0);
            assertThat(x.suggested()).isEqualTo(11.0);
        });
    }

    @Test
    void failedRepsLowerTheWeight() {
        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(bench(10, 40.0)),
                List.of(session(BENCH, 2, 8, 2, 9, 40.0, 1, null)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> {
            assertThat(x.metric()).isEqualTo(Metric.WEIGHT);
            assertThat(x.suggested()).isEqualTo(36.0);
            assertThat(x.changePercent()).isEqualTo(-10);
            assertThat(x.reason()).isEqualTo(AdjustmentReason.FAILED_REPS);
            assertThat(x.increases()).isFalse();
        });
    }

    @Test
    void progressesFromWhatWasLiftedNotFromThePlan() {
        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(bench(15, 40.0)),
                List.of(session(BENCH, 1, 6, 3, 15, 45.0, 0, null)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> {
            assertThat(x.previous()).isEqualTo(45.0);
            assertThat(x.suggested()).isEqualTo(47.5);
        });
    }

    @Test
    void noSuggestionWhenTheRoutineAlreadyAsksForIt() {
        // La sugerencia de después de la sesión ya se aplicó: la rutina pide 42 kg.
        assertThat(LoadSuggestions.forDay(List.of(bench(15, 42.0)),
                List.of(session(BENCH, 3, 6, 3, 15, 40.0, 0, null)), HYPERTROPHY, NOW)).isEmpty();
    }

    @Test
    void noSuggestionAfterTooLongOrWithAMiddlingEffort() {
        assertThat(LoadSuggestions.forDay(List.of(bench(15, 40.0)),
                List.of(session(BENCH, 20, 6, 3, 15, 40.0, 0, null)), HYPERTROPHY, NOW)).isEmpty();
        assertThat(LoadSuggestions.forDay(List.of(bench(10, 40.0)),
                List.of(session(BENCH, 2, 8, 3, 10, 40.0, 0, null)), HYPERTROPHY, NOW)).isEmpty();
        assertThat(LoadSuggestions.forDay(List.of(bench(10, 40.0)), List.of(), HYPERTROPHY, NOW)).isEmpty();
    }

    @Test
    void usesTheLastSessionWhereThatExerciseWasDone() {
        CompletedSessionSummary other = new CompletedSessionSummary(UUID.randomUUID(), NOW.minus(Duration.ofDays(1)),
                9, 30, List.of());
        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(bench(15, 40.0)),
                List.of(other, session(BENCH, 4, 6, 3, 15, 40.0, 0, null)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> assertThat(x.lastRpe()).isEqualTo(6));
    }

    @Test
    void anEasyPlankHoldsTenSecondsLonger() {
        PlannedExercise plank = new PlannedExercise(UUID.randomUUID(), PLANK,
                new ExerciseParameters(3, 1, 60, null, null, null, null, 30), 1, null);

        List<LoadSuggestion> s = LoadSuggestions.forDay(List.of(plank),
                List.of(session(PLANK, 2, 4, 3, null, null, 0, 30)), HYPERTROPHY, NOW);

        assertThat(s).singleElement().satisfies(x -> {
            assertThat(x.metric()).isEqualTo(Metric.HOLD_SECONDS);
            assertThat(x.previous()).isEqualTo(30.0);
            assertThat(x.suggested()).isEqualTo(40.0);
        });
    }
}
