package com.synaptixfit.domain.model.training.load;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Peso de partida (ADR 0054): historial → fracción del peso corporal → por defecto, redondeo al material y topes. */
class StartingLoadTest {

    private static final Instant NOW = Instant.parse("2026-11-16T10:00:00Z");
    private static final UUID EXERCISE = UUID.randomUUID();

    private static final LoadProfile SQUAT = new LoadProfile(LoadType.BARBELL, 0.35, 20.0, 60.0, true);
    private static final LoadProfile BENCH = new LoadProfile(LoadType.BARBELL, 0.25, 20.0, 40.0, false);
    private static final LoadProfile DB_BENCH = new LoadProfile(LoadType.DUMBBELL_PAIR, 0.08, 6.0, 16.0, false);
    private static final LoadProfile GOBLET = new LoadProfile(LoadType.KETTLEBELL, 0.15, 8.0, 16.0, true);
    private static final LoadProfile SUMO = new LoadProfile(LoadType.DUMBBELL_SINGLE, 0.15, 8.0, 16.0, true);
    private static final LoadProfile PRESS_MACHINE = new LoadProfile(LoadType.MACHINE, null, null, null, false);
    private static final LoadProfile PUSH_UP = new LoadProfile(LoadType.BODYWEIGHT, null, null, null, false);

    @Test
    void theAuditTableExamplesForSixtyAndEightyKilos() {
        assertThat(StartingLoad.forExercise(SQUAT, null, 60.0, TemplateLevel.BEGINNER)).isEqualTo(20.0);
        assertThat(StartingLoad.forExercise(SQUAT, null, 80.0, TemplateLevel.BEGINNER)).isEqualTo(27.5);
        assertThat(StartingLoad.forExercise(BENCH, null, 80.0, TemplateLevel.BEGINNER)).isEqualTo(20.0);
        assertThat(StartingLoad.forExercise(DB_BENCH, null, 60.0, TemplateLevel.BEGINNER)).isEqualTo(4.0);
        assertThat(StartingLoad.forExercise(DB_BENCH, null, 80.0, TemplateLevel.BEGINNER)).isEqualTo(6.0);
        assertThat(StartingLoad.forExercise(GOBLET, null, 60.0, TemplateLevel.BEGINNER)).isEqualTo(8.0);
        assertThat(StartingLoad.forExercise(GOBLET, null, 80.0, TemplateLevel.BEGINNER)).isEqualTo(12.0);
        assertThat(StartingLoad.forExercise(SUMO, null, 60.0, TemplateLevel.BEGINNER)).isEqualTo(8.0);
    }

    @Test
    void withoutBodyWeightTheDefaultIsUsed() {
        assertThat(StartingLoad.forExercise(SQUAT, null, null, TemplateLevel.BEGINNER)).isEqualTo(20.0);
        assertThat(StartingLoad.forExercise(DB_BENCH, null, null, TemplateLevel.BEGINNER)).isEqualTo(6.0);
    }

    @Test
    void theFirstDayNeverGoesPastTheCapAndRoundsDownToTheMaterial() {
        // 150 kg × 0,35 = 52,5 → sin tope; 200 kg × 0,35 = 70 → tope 60.
        assertThat(StartingLoad.forExercise(SQUAT, null, 150.0, TemplateLevel.BEGINNER)).isEqualTo(52.5);
        assertThat(StartingLoad.forExercise(SQUAT, null, 200.0, TemplateLevel.BEGINNER)).isEqualTo(60.0);
        assertThat(StartingLoad.forExercise(DB_BENCH, null, 300.0, TemplateLevel.BEGINNER)).isEqualTo(16.0);
        // 73 kg × 0,08 = 5,84 → mancuerna de 4 (de 2 en 2 hacia abajo).
        assertThat(StartingLoad.forExercise(DB_BENCH, null, 73.0, TemplateLevel.BEGINNER)).isEqualTo(4.0);
    }

    @Test
    void historyWinsOverEverythingAndIsNotCapped() {
        assertThat(StartingLoad.forExercise(SQUAT, 85.0, 60.0, TemplateLevel.BEGINNER)).isEqualTo(85.0);
        assertThat(StartingLoad.forExercise(PRESS_MACHINE, 35.0, 60.0, TemplateLevel.BEGINNER)).isEqualTo(35.0);
        assertThat(StartingLoad.forExercise(SQUAT, 70.0, null, TemplateLevel.INTERMEDIATE)).isEqualTo(70.0);
    }

    @Test
    void machinesBodyweightIntermediatesAndUnknownExercisesGetNoKilos() {
        assertThat(StartingLoad.forExercise(PRESS_MACHINE, null, 70.0, TemplateLevel.BEGINNER)).isNull();
        assertThat(StartingLoad.forExercise(PUSH_UP, null, 70.0, TemplateLevel.BEGINNER)).isNull();
        assertThat(StartingLoad.forExercise(SQUAT, null, 70.0, TemplateLevel.INTERMEDIATE)).isNull();
        assertThat(StartingLoad.forExercise(null, null, 70.0, TemplateLevel.BEGINNER)).isNull();
    }

    @Test
    void historyIsTheHeaviestWorkingSetOfTheLastSessionWithinSixWeeksAndTwelveReps() {
        List<CompletedSessionSummary> recent = List.of(
                session(NOW.minus(Duration.ofDays(2)), set(15, 50.0)),
                session(NOW.minus(Duration.ofDays(5)), set(10, 40.0), set(8, 42.5)),
                session(NOW.minus(Duration.ofDays(9)), set(8, 60.0)));

        assertThat(StartingLoad.historyKg(recent, EXERCISE, NOW)).isEqualTo(42.5);
        assertThat(StartingLoad.historyKg(List.of(session(NOW.minus(Duration.ofDays(50)), set(8, 60.0))), EXERCISE,
                NOW)).isNull();
        assertThat(StartingLoad.doneWithWeight(recent, EXERCISE, NOW)).isTrue();
        assertThat(StartingLoad.doneWithWeight(recent, UUID.randomUUID(), NOW)).isFalse();
    }

    private static CompletedSessionSummary session(Instant at, SessionSet... sets) {
        return new CompletedSessionSummary(UUID.randomUUID(), at, 7, 40,
                List.of(sets).stream().map(s -> new PerformedSet(EXERCISE, "Sentadilla", s)).toList());
    }

    private static SessionSet set(int reps, double kg) {
        return new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, reps, kg, true, 0, null, null, EXERCISE);
    }
}
