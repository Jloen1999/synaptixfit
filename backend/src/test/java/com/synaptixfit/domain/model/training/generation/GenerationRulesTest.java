package com.synaptixfit.domain.model.training.generation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement.RefinedExercise;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Motor de reglas, progresión, contexto, periodización, nombre y reparación de la salida de la IA. */
class GenerationRulesTest {

    private static final List<MeasurementType> REPS_WEIGHT = List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT);
    private static final GoalParameters HYP = GoalParameters.of(TrainingGoal.HYPERTROPHY);

    private static SessionSet set(int failed) {
        return new SessionSet(UUID.randomUUID(), null, 1, 10, 50.0, failed == 0, failed);
    }

    private static Exercise exercise(String name, Difficulty difficulty, List<String> equipment, List<String> parts) {
        return new Exercise(UUID.randomUUID(), name, null, List.of(), difficulty, List.of("Hipertrofia Muscular"),
                Modality.STRENGTH, REPS_WEIGHT, false, true, 6.0, null, null,
                parts.stream().map(p -> new CatalogItem(1, p, null)).toList(),
                List.of(new CatalogItem(2, "Cuádriceps", null)), List.of(),
                equipment.stream().map(e -> new CatalogItem(3, e, null)).toList(), Instant.EPOCH, Instant.EPOCH);
    }

    private static TrainingProfile profile(double bmi, ActivityLevel level, List<String> equipment) {
        return new TrainingProfile(30, "hombre", 80, 180, bmi, level, TrainingGoal.HYPERTROPHY, equipment, 3, 60, List.of());
    }

    // ------------------------------------------------------------------ progresión

    @Test
    void progressionFollowsRpeAndFailures() {
        ExerciseParameters p = new ExerciseParameters(3, 10, 90, 50.0, null, null, null, null);
        assertThat(ProgressionCalculator.progress(p, REPS_WEIGHT, 6, List.of(set(0)), HYP).parameters().reps()).isEqualTo(11);
        ExerciseParameters top = new ExerciseParameters(3, 15, 90, 50.0, null, null, null, null);
        ExerciseParameters bumped = ProgressionCalculator.progress(top, REPS_WEIGHT, 6, List.of(set(0)), HYP).parameters();
        assertThat(bumped.weightKg()).isEqualTo(52.5);
        assertThat(bumped.reps()).isEqualTo(6);
        assertThat(bumped.weightsKg()).containsExactly(26.5, 39.5, 52.5);
        assertThat(ProgressionCalculator.progress(p, REPS_WEIGHT, 4, List.of(), HYP).parameters().weightKg()).isEqualTo(55.0);
        assertThat(ProgressionCalculator.progress(p, REPS_WEIGHT, 10, List.of(), HYP).parameters().weightKg()).isEqualTo(42.5);
        ProgressionCalculator.Result failed = ProgressionCalculator.progress(new ExerciseParameters(4, 10, 90, 50.0, null,
                null, null, null), REPS_WEIGHT, 8, List.of(set(2), set(1)), HYP);
        assertThat(failed.parameters().weightKg()).isEqualTo(42.5);
        assertThat(failed.parameters().sets()).isEqualTo(3);
        assertThat(failed.log()).contains("3 fallos");
        // El motivo viaja como código para que la app lo explique en su idioma.
        assertThat(failed.reason()).isEqualTo(AdjustmentReason.FAILED_REPS);
        assertThat(ProgressionCalculator.progress(p, REPS_WEIGHT, 6, List.of(set(0)), HYP).reason())
                .isEqualTo(AdjustmentReason.LOW_RPE_MORE_REPS);
        assertThat(ProgressionCalculator.progress(top, REPS_WEIGHT, 6, List.of(set(0)), HYP).reason())
                .isEqualTo(AdjustmentReason.LOW_RPE_MORE_WEIGHT);
        assertThat(ProgressionCalculator.degradeForInactivity(p, REPS_WEIGHT, 20, HYP).reason())
                .isEqualTo(AdjustmentReason.INACTIVITY);
        assertThat(ProgressionCalculator.progress(p, REPS_WEIGHT, 8, List.of(), HYP).changed(p)).isFalse();
    }

    @Test
    void progressionSupportsIsometricAndTimedExercises() {
        List<MeasurementType> time = List.of(MeasurementType.TIME);
        ExerciseParameters iso = new ExerciseParameters(3, 1, 60, null, null, null, null, 30);
        assertThat(ProgressionCalculator.progress(iso, time, 4, List.of(), HYP).parameters().isometricSeconds()).isEqualTo(40);
        assertThat(ProgressionCalculator.progress(iso, time, 10, List.of(), HYP).parameters().isometricSeconds()).isEqualTo(26);
        ExerciseParameters cardio = new ExerciseParameters(1, 1, 30, null, null, 1000, 2000, null);
        ExerciseParameters harder = ProgressionCalculator.progress(cardio, List.of(MeasurementType.TIME,
                MeasurementType.DISTANCE), 6, List.of(), null).parameters();
        assertThat(harder.targetDurationSeconds()).isEqualTo(1100);
    }

    @Test
    void inactivityDegradesLoad() {
        ExerciseParameters p = new ExerciseParameters(3, 10, 90, 50.0, null, null, null, null);
        assertThat(ProgressionCalculator.degradeForInactivity(p, REPS_WEIGHT, 10, HYP).parameters()).isEqualTo(p);
        ExerciseParameters d15 = ProgressionCalculator.degradeForInactivity(p, REPS_WEIGHT, 15, HYP).parameters();
        assertThat(d15.weightKg()).isEqualTo(40.0);
        assertThat(d15.restSeconds()).isEqualTo(120);
        assertThat(d15.sets()).isEqualTo(3);
        assertThat(ProgressionCalculator.degradeForInactivity(p, REPS_WEIGHT, 30, HYP).parameters().weightKg()).isEqualTo(35.0);
        assertThat(ProgressionCalculator.oneRepMax(100, 1)).isEqualTo(100);
        assertThat(ProgressionCalculator.oneRepMax(100, 5)).isGreaterThan(100);
    }

    // ------------------------------------------------------------------ elegibilidad y reglas

    @Test
    void eligibilityChecksEquipmentLevelAndImpact() {
        Exercise dumbbell = exercise("Curl con mancuernas", Difficulty.BEGINNER, List.of("Mancuernas"), List.of("Brazos"));
        Exercise kettlebell = exercise("Swing", Difficulty.BEGINNER, List.of("Pesa rusa"), List.of("Cadera"));
        Exercise bodyweight = exercise("Flexión", Difficulty.ADVANCED, List.of("Peso corporal"), List.of("Pecho"));
        Exercise jump = exercise("Sentadilla con salto", Difficulty.BEGINNER, List.of(), List.of("Piernas"));
        TrainingProfile user = profile(24, ActivityLevel.LIGHT, List.of("mancuerna", "kettlebell"));
        assertThat(ExerciseEligibility.eligible(dumbbell, user)).isTrue();
        assertThat(ExerciseEligibility.eligible(kettlebell, user)).isTrue();
        assertThat(ExerciseEligibility.eligible(bodyweight, user)).isFalse();
        assertThat(ExerciseEligibility.eligible(bodyweight, profile(24, ActivityLevel.MODERATE, List.of()))).isTrue();
        assertThat(ExerciseEligibility.eligible(jump, user)).isTrue();
        assertThat(ExerciseEligibility.eligible(jump, profile(32, ActivityLevel.LIGHT, List.of()))).isFalse();
    }

    @Test
    void splitDependsOnDaysAndLevel() {
        assertThat(RoutineRuleEngine.chooseSplit(3, ActivityLevel.HIGH)).isEqualTo(RoutineRuleEngine.Split.FULL_BODY);
        assertThat(RoutineRuleEngine.chooseSplit(4, ActivityLevel.LIGHT)).isEqualTo(RoutineRuleEngine.Split.FULL_BODY);
        assertThat(RoutineRuleEngine.chooseSplit(4, ActivityLevel.MODERATE)).isEqualTo(RoutineRuleEngine.Split.UPPER_LOWER);
        assertThat(RoutineRuleEngine.chooseSplit(6, ActivityLevel.SEDENTARY)).isEqualTo(RoutineRuleEngine.Split.PUSH_PULL_LEGS);
        assertThat(RoutineRuleEngine.dayName(1, RoutineRuleEngine.PUSH)).isEqualTo("D1 · Empuje");
        assertThat(RoutineRuleEngine.dayName(3, RoutineRuleEngine.ALL)).isEqualTo("D3 · Full-Body");
        GoalParameters older = RoutineRuleEngine.adjustForBiometrics(HYP,
                new TrainingProfile(55, "mujer", 70, 165, 31, ActivityLevel.LIGHT, TrainingGoal.HYPERTROPHY, List.of(), 3, 45, List.of()));
        assertThat(older.relativeIntensity()).isEqualTo(0.65);
        assertThat(older.repsMin()).isEqualTo(8);
    }

    @Test
    void ruleEngineSkipsRecentExercisesUnlessNothingElseFits() {
        Exercise a = exercise("Sentadilla", Difficulty.BEGINNER, List.of(), List.of("Piernas"));
        Exercise b = exercise("Zancada", Difficulty.BEGINNER, List.of(), List.of("Piernas"));
        TrainingProfile user = new TrainingProfile(25, "hombre", 80, 180, 24, ActivityLevel.MODERATE,
                TrainingGoal.HYPERTROPHY, List.of(), 1, 60, List.of(2));
        TrainingHistory history = new TrainingHistory(3, 7, java.util.Set.of("sentadilla"), 2, Map.of(), 1, false);
        var template = RoutineRuleEngine.generate(user, List.of(a, b), HYP, history);
        assertThat(template.days()).singleElement().satisfies(d -> {
            assertThat(d.dayNumber()).isEqualTo(2);
            assertThat(d.exercises()).extracting(ProposedExercise::exerciseName).containsExactly("Zancada");
            assertThat(d.exercises().getFirst().parameters().weightKg()).isEqualTo(8.5);
        });
        var onlyRecent = RoutineRuleEngine.generate(user, List.of(a), HYP, history);
        assertThat(onlyRecent.exerciseCount()).isEqualTo(1);
    }

    // ------------------------------------------------------------------ contexto

    @Test
    void totalLoadFactorAndAdjustments() {
        AcademicContext calm = AcademicContext.NONE;
        assertThat(ContextAdjuster.totalLoadFactor(calm, null)).isCloseTo(0.125 + 0.15 / 8, within(1e-9));
        ContextAdjuster.Adjustment neutral = ContextAdjuster.compute(calm, PhysiologicalContext.NONE, null);
        assertThat(neutral.isNeutral()).isTrue();

        DailyCheckIn tired = DailyCheckIn.create(UUID.randomUUID(), LocalDate.now(),
                new DailyCheckIn.Values(2, 4, 2, 4, List.of(), false, null), Instant.now());
        AcademicContext exams = new AcademicContext(10, 30, 9, 5, 0, 4, 5, 2, null, 1.8);
        ContextAdjuster.Adjustment heavy = ContextAdjuster.compute(exams, new PhysiologicalContext(70.0, 71.0, 0, 3), tired);
        assertThat(heavy.volumeFactor()).isEqualTo(0.3);
        assertThat(heavy.deltaSets()).isEqualTo(-3);
        assertThat(heavy.deltaRest()).isEqualTo(60);
        assertThat(heavy.reasons()).contains("Modo exámenes activo", "Sin racha activa, rutina de reenganche",
                "Tendencia de pérdida de peso, preservar masa muscular", "No te sientes listo para entrenar");
        assertThat(heavy.reasons()).anyMatch(r -> r.startsWith("Carga física aguda alta"));

        ProposedDay day = new ProposedDay(1, "D1", java.util.stream.IntStream.range(0, 5).mapToObj(i ->
                new ProposedExercise(UUID.randomUUID(), "E" + i, new ExerciseParameters(3, 10, 90, 40.0, null, null, null, null)))
                .toList());
        ProposedDay adjusted = ContextAdjuster.apply(List.of(day), heavy, HYP).getFirst();
        assertThat(adjusted.exercises()).hasSize(2);
        assertThat(adjusted.exercises().getFirst().parameters().sets()).isEqualTo(1);
        assertThat(adjusted.exercises().getFirst().parameters().restSeconds()).isEqualTo(150);
        assertThat(ContextAdjuster.energyState(tired, exams)).isLessThan(30);
    }

    @Test
    void checkInFilterRemovesPainfulMusclesAndAddsMobilityWhenStressed() {
        Exercise legs = exercise("Prensa", Difficulty.BEGINNER, List.of(), List.of("Piernas"));
        Exercise mobility = new Exercise(UUID.randomUUID(), "Movilidad de cadera", null, List.of(), Difficulty.BEGINNER,
                List.of(), Modality.MOBILITY, List.of(MeasurementType.TIME), false, true, 2.3, null, null, List.of(),
                List.of(new CatalogItem(9, "Glúteo medio", null)), List.of(), List.of(), Instant.EPOCH, Instant.EPOCH);
        DailyCheckIn checkIn = DailyCheckIn.create(UUID.randomUUID(), LocalDate.now(),
                new DailyCheckIn.Values(4, 5, 4, 2, List.of("Piernas"), true, null), Instant.now());
        ProposedDay day = new ProposedDay(1, null, List.of(new ProposedExercise(legs.id(), legs.name(),
                new ExerciseParameters(3, 10, 90, null, null, null, null, null))));
        ProposedDay filtered = ContextAdjuster.filterByCheckIn(List.of(day), checkIn, List.of(legs, mobility)).getFirst();
        assertThat(filtered.exercises()).extracting(ProposedExercise::exerciseName).containsExactly("Movilidad de cadera");
        assertThat(filtered.exercises().getFirst().parameters().isometricSeconds()).isEqualTo(30);
    }

    // ------------------------------------------------------------------ periodización, transición y nombre

    @Test
    void periodizationExpandsEveryWeek() {
        ProposedDay day = new ProposedDay(1, "D1", List.of(new ProposedExercise(UUID.randomUUID(), "E",
                new ExerciseParameters(4, 10, 90, 100.0, null, 600, null, null))));
        var weeks = Periodization.expand(List.of(day), 5, false);
        assertThat(weeks).extracting(RoutineProposal.ProposedWeek::type).containsExactly(WeekType.ADAPTATION,
                WeekType.LOAD, WeekType.LOAD, WeekType.LOAD, WeekType.DELOAD);
        assertThat(weeks.get(0).days().getFirst().exercises().getFirst().parameters().weightKg()).isEqualTo(90.0);
        assertThat(weeks.get(0).days().getFirst().exercises().getFirst().parameters().sets()).isEqualTo(3);
        assertThat(weeks.get(1).days().getFirst().exercises().getFirst().parameters().weightKg()).isEqualTo(100.0);
        assertThat(weeks.get(3).days().getFirst().exercises().getFirst().parameters().weightKg()).isEqualTo(105.0);
        ExerciseParameters deload = weeks.get(4).days().getFirst().exercises().getFirst().parameters();
        assertThat(deload.sets()).isEqualTo(2);
        assertThat(deload.weightKg()).isEqualTo(70.0);
        assertThat(deload.targetDurationSeconds()).isEqualTo(420);
        assertThat(weeks.get(4).name()).isEqualTo("Semana 5: Descarga");
        assertThat(Periodization.expand(List.of(day), 3, true).getFirst().type()).isEqualTo(WeekType.DELOAD);
    }

    @Test
    void goalTransitionInterpolatesRanges() {
        GoalTransition.Transition t = GoalTransition.compute(TrainingGoal.MAX_STRENGTH, TrainingGoal.STRENGTH_ENDURANCE, 0);
        assertThat(t.active()).isTrue();
        assertThat(t.factor()).isEqualTo(0.30);
        assertThat(t.parameters().repsMax()).isEqualTo(19);
        assertThat(t.reason()).contains("Fuerza Resistencia → Fuerza Máxima");
        assertThat(GoalTransition.compute(TrainingGoal.MAX_STRENGTH, TrainingGoal.STRENGTH_ENDURANCE, 3).active()).isFalse();
        assertThat(GoalTransition.compute(TrainingGoal.MAX_STRENGTH, null, 0).active()).isFalse();
    }

    @Test
    void nameSanitizationFixesWrongDurations() {
        assertThat(RoutineNaming.sanitize("Fuerza total en 4 semanas", 1, "x")).isEqualTo("Fuerza total en 1 semana");
        assertThat(RoutineNaming.sanitize("Plan de 1 semana", 3, "x")).isEqualTo("Plan de 3 semanas");
        assertThat(RoutineNaming.sanitize("Sin duración", 2, "x")).isEqualTo("Sin duración");
        assertThat(RoutineNaming.sanitize("  ", 2, "Base")).isEqualTo("Base");
        assertThat(RoutineNaming.sanitize("A".repeat(200), 2, "Base")).hasSize(120);
        assertThat(RoutineNaming.baseName(TrainingGoal.POWER, "Upper/Lower", 1))
                .isEqualTo("Potencia y Explosividad · Upper/Lower · 1 semana");
    }

    @Test
    void repairRejectsUnknownOrIneligibleExercisesAndOutOfRangeValues() {
        TrainingProfile user = profile(24, ActivityLevel.SEDENTARY, List.of());
        Exercise ok = exercise("Sentadilla", Difficulty.BEGINNER, List.of(), List.of("Piernas"));
        Exercise advanced = exercise("Pistol", Difficulty.ADVANCED, List.of(), List.of("Piernas"));
        ProposedExercise base = new ProposedExercise(UUID.randomUUID(), "Base",
                new ExerciseParameters(3, 10, 90, 40.0, List.of(20.0, 30.0, 40.0), null, null, null));
        List<ProposedDay> days = List.of(new ProposedDay(1, null, List.of(base, base, base, base)));
        Map<UUID, Exercise> catalog = Map.of(ok.id(), ok, advanced.id(), advanced);
        List<RefinedExercise> ai = List.of(
                new RefinedExercise(ok.id(), 4, 12, 20, null, null, null, null),
                new RefinedExercise(advanced.id(), 3, 10, 90, null, null, null, null),
                new RefinedExercise(UUID.randomUUID(), 3, 10, 90, null, null, null, null));
        List<ProposedExercise> repaired = ProposalRepair.repair(days, Map.of(1, ai), catalog, user).getFirst().exercises();
        assertThat(repaired).hasSize(4);
        assertThat(repaired.get(0).exerciseId()).isEqualTo(ok.id());
        assertThat(repaired.get(0).parameters().sets()).isEqualTo(4);
        assertThat(repaired.get(0).parameters().restSeconds()).isEqualTo(30);
        assertThat(repaired.get(0).parameters().weightKg()).isEqualTo(40.0);
        assertThat(repaired.get(0).parameters().weightsKg()).hasSize(4);
        assertThat(repaired.get(1)).isEqualTo(base);
        assertThat(repaired.get(2)).isEqualTo(base);
        assertThat(repaired.get(3)).isEqualTo(base);
    }

    // ------------------------------------------------------------------ historial

    @Test
    void historyDetectsDeloadAndRecentPerformance() {
        UUID exerciseId = UUID.randomUUID();
        LocalDate today = LocalDate.of(2026, 10, 7);
        List<CompletedSessionSummary> sessions = List.of(
                summary("2026-10-06T10:00:00Z", 9, 30, exerciseId),
                summary("2026-09-29T10:00:00Z", 9, 40, exerciseId),
                summary("2026-09-22T10:00:00Z", 9, 50, exerciseId));
        TrainingHistory h = TrainingHistory.from(sessions, today, ZoneOffset.UTC, null);
        assertThat(h.daysSinceLastSession()).isEqualTo(1);
        assertThat(h.consecutiveWeeks()).isEqualTo(3);
        assertThat(h.requiresDeload()).isTrue();
        assertThat(h.recentExerciseNames()).containsExactly("sentadilla");
        assertThat(h.performances().get(exerciseId).rpe()).isEqualTo(9.0);
        assertThat(TrainingHistory.from(List.of(), today, ZoneOffset.UTC, 60).requiresDeload()).isTrue();
        assertThat(TrainingHistory.from(List.of(), today, ZoneOffset.UTC, null).requiresDeload()).isFalse();
    }

    private static CompletedSessionSummary summary(String when, int rpe, int minutes, UUID exerciseId) {
        return new CompletedSessionSummary(UUID.randomUUID(), Instant.parse(when), rpe, minutes, List.of(
                new CompletedSessionSummary.PerformedSet(exerciseId, "Sentadilla", set(0))));
    }
}
