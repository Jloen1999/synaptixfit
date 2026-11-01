package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.training.RoutineDayDuplicatedException;
import com.synaptixfit.domain.exception.training.RoutineHasEmptyDaysException;
import com.synaptixfit.domain.exception.training.RoutineReorderMismatchException;
import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas del dominio de entrenamiento: estados de semana/día, sesiones, XP, calorías y check-in. */
class TrainingDomainTest {

    private static final Instant NOW = Instant.parse("2026-10-05T10:00:00Z");
    private static final ExerciseRef REF = new ExerciseRef(UUID.randomUUID(), "Press", null, null, Modality.STRENGTH,
            List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), false, 6.0, true);
    private static final ExerciseParameters P = new ExerciseParameters(3, 10, 90, null, null, null, null, null);

    private static Routine routine(RoutineDay... days) {
        return Routine.create(UUID.randomUUID(), "Rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY, null,
                null, List.of(RoutineWeek.create(1, null, null, List.of(days))), NOW);
    }

    private static final LocalDate DAY = LocalDate.of(2026, 10, 5);

    private static RoutineDay trainable(int number) {
        RoutineDay day = RoutineDay.create(number, null);
        day.addExercise(REF, P);
        return day;
    }

    @Test
    void weekStatusIsDerivedFromItsDays() {
        RoutineDay a = trainable(1);
        RoutineDay b = trainable(2);
        Routine r = routine(a, b);
        RoutineWeek week = r.weeks().getFirst();
        assertThat(week.status()).isEqualTo(ProgressStatus.PENDING);
        r.startDay(a.id(), LocalDate.of(2026, 10, 5));
        assertThat(week.status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        r.completeDay(a.id(), DAY);
        assertThat(week.status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        r.completeDay(b.id(), DAY);
        assertThat(week.status()).isEqualTo(ProgressStatus.COMPLETED);
        r.resetDay(a.id());
        assertThat(week.status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        r.resetDay(b.id());
        assertThat(week.status()).isEqualTo(ProgressStatus.PENDING);
        assertThat(r.startDate()).isEqualTo(LocalDate.of(2026, 10, 5));
    }

    @Test
    void completedDayDoesNotGoBackWhenAnotherSessionStarts() {
        RoutineDay a = trainable(1);
        Routine r = routine(a);
        r.completeDay(a.id(), DAY);
        r.startDay(a.id(), LocalDate.now());
        assertThat(r.day(a.id()).status()).isEqualTo(ProgressStatus.COMPLETED);
    }

    @Test
    void completingALaterDaySkipsTheEarlierOnesAndClosesTheCycle() {
        RoutineDay a = trainable(1);
        RoutineDay empty = RoutineDay.create(2, null);
        RoutineDay c = trainable(3);
        Routine r = routine(a, empty, c);
        RoutineWeek week = r.weeks().getFirst();

        List<UUID> skipped = r.completeDay(c.id(), DAY);

        assertThat(skipped).containsExactly(a.id());
        assertThat(r.day(a.id()).status()).isEqualTo(ProgressStatus.SKIPPED);
        assertThat(r.day(empty.id()).status()).isEqualTo(ProgressStatus.PENDING);
        assertThat(week.status()).isEqualTo(ProgressStatus.COMPLETED);
        assertThat(r.finishCycleIfDone()).isTrue();
        assertThat(r.status()).isEqualTo(RoutineStatus.COMPLETED);
        assertThat(r.finishCycleIfDone()).isFalse();

        assertThat(r.unskipDay(a.id())).isTrue();
        assertThat(r.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(r.day(a.id()).closedOn()).isNull();
        assertThat(week.status()).isEqualTo(ProgressStatus.IN_PROGRESS);
    }

    @Test
    void completingADayWithoutExercisesSkipsNothing() {
        RoutineDay a = trainable(1);
        RoutineDay empty = RoutineDay.create(3, null);
        Routine r = routine(a, empty);
        assertThat(r.completeDay(empty.id(), DAY)).isEmpty();
        assertThat(r.day(a.id()).status()).isEqualTo(ProgressStatus.PENDING);
        assertThat(r.finishCycleIfDone()).isFalse();
    }

    @Test
    void aCompletedDayCannotBeSkippedAndRestartResetsTheCycle() {
        RoutineDay a = trainable(1);
        Routine r = routine(a);
        r.completeDay(a.id(), DAY);
        assertThatThrownBy(() -> r.skipDay(a.id(), DAY))
                .isInstanceOf(com.synaptixfit.domain.exception.training.RoutineDayNotSkippableException.class);
        r.finishCycleIfDone();
        r.restart(DAY.plusDays(3));
        assertThat(r.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(r.startDate()).isEqualTo(DAY.plusDays(3));
        assertThat(r.day(a.id()).status()).isEqualTo(ProgressStatus.PENDING);
        assertThat(r.lastClosedOn()).isEmpty();
    }

    @Test
    void copiesArePausedAndDayNamesAreOptional() {
        RoutineDay a = RoutineDay.create(1, "  ");
        Routine r = routine(a);
        assertThat(r.day(a.id()).name()).isNull();
        assertThat(r.copyFor(UUID.randomUUID(), null, null, NOW).status()).isEqualTo(RoutineStatus.PAUSED);
    }

    @Test
    void anAbandonedSessionFinishesOnItsOwnDayAndOnlyTodaysSessionsCanBeUnmarked() {
        TrainingSession s = TrainingSession.start(UUID.randomUUID(), null, null, NOW);
        Instant twoDaysLater = NOW.plus(java.time.Duration.ofDays(2));
        long duration = s.boundedDurationSeconds(3_600, twoDaysLater);
        Instant completedAt = s.completionInstant(duration, twoDaysLater);
        assertThat(completedAt).isEqualTo(NOW.plusSeconds(3_600));
        s.complete(duration, 7, 100, 10, completedAt);
        assertThat(s.completedOn(java.time.ZoneOffset.UTC)).isEqualTo(LocalDate.of(2026, 10, 5));
        assertThatThrownBy(() -> s.unmark(LocalDate.of(2026, 10, 7), java.time.ZoneOffset.UTC))
                .isInstanceOf(com.synaptixfit.domain.exception.training.SessionUnmarkExpiredException.class);
        s.correct(5, 45, 80);
        assertThat(s.rpe()).isEqualTo(5);
        assertThat(s.durationMinutes()).isEqualTo(45);
        assertThat(s.xpAwarded()).isEqualTo(10);
    }

    @Test
    void weekWithoutDaysIsPendingAndDuplicatedDaysAreRejected() {
        RoutineWeek empty = RoutineWeek.create(1, null, WeekType.LOAD, List.of());
        assertThat(empty.status()).isEqualTo(ProgressStatus.PENDING);
        empty.addDay(3, null);
        assertThatThrownBy(() -> empty.addDay(3, "otro")).isInstanceOf(RoutineDayDuplicatedException.class);
        assertThatThrownBy(() -> empty.addDay(8, null)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void routineCanOnlyBeCompletedWithoutEmptyDays() {
        RoutineDay a = RoutineDay.create(1, null);
        Routine r = routine(a);
        assertThatThrownBy(() -> r.changeStatus(RoutineStatus.COMPLETED)).isInstanceOf(RoutineHasEmptyDaysException.class);
        r.addExercise(a.id(), REF, P);
        r.changeStatus(RoutineStatus.COMPLETED);
        r.addWeek(null, null);
        assertThat(r.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(r.weeks().get(1).type()).isEqualTo(WeekType.LOAD);
    }

    @Test
    void exerciseCountAndOrderStayConsistent() {
        RoutineDay a = RoutineDay.create(1, null);
        Routine r = routine(a);
        PlannedExercise x = r.addExercise(a.id(), REF, P);
        PlannedExercise y = r.addExercise(a.id(), REF, P);
        PlannedExercise z = r.addExercise(a.id(), REF, P);
        assertThat(r.exerciseCount()).isEqualTo(3);
        r.removeExercise(y.id());
        assertThat(r.day(a.id()).exercises()).extracting(PlannedExercise::order).containsExactly(1, 2);
        assertThatThrownBy(() -> r.reorderExercises(a.id(), List.of(z.id()))).isInstanceOf(RoutineReorderMismatchException.class);
        assertThatThrownBy(() -> r.reorderExercises(a.id(), List.of(z.id(), z.id())))
                .isInstanceOf(RoutineReorderMismatchException.class);
        r.reorderExercises(a.id(), List.of(z.id(), x.id()));
        assertThat(r.day(a.id()).exercises()).extracting(PlannedExercise::id).containsExactly(z.id(), x.id());
    }

    @Test
    void parametersEnforceDatabaseRangesAndClampedFitsThem() {
        assertThatThrownBy(() -> new ExerciseParameters(11, 10, 90, null, null, null, null, null))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new ExerciseParameters(3, 10, 20, null, null, null, null, null))
                .isInstanceOf(FieldValidationException.class);
        ExerciseParameters c = ExerciseParameters.clamped(0, 200, 10, 41.26, List.of(20.1, 600.0), 0, null, 900);
        assertThat(c.sets()).isEqualTo(1);
        assertThat(c.reps()).isEqualTo(100);
        assertThat(c.restSeconds()).isEqualTo(30);
        // Con 1 serie, la lista se recorta a esa serie y el peso común pasa a ser el suyo (ADR 0027).
        assertThat(c.weightKg()).isEqualTo(20.0);
        assertThat(c.weightsKg()).isNull();
        ExerciseParameters two = ExerciseParameters.clamped(2, 10, 90, 41.26, List.of(20.1, 600.0), null, null, null);
        assertThat(two.weightsKg()).containsExactly(20.0, 500.0);
        assertThat(two.weightKg()).isEqualTo(500.0);
        assertThat(c.targetDurationSeconds()).isEqualTo(1);
        assertThat(c.isometricSeconds()).isEqualTo(600);
    }

    @Test
    void aSessionLeftOpenIsStaleAndItsDurationIsBounded() {
        TrainingSession s = TrainingSession.start(UUID.randomUUID(), null, null, NOW);
        assertThat(s.isStale(NOW.plusSeconds(5 * 3600))).isFalse();
        assertThat(s.isStale(NOW.plusSeconds(7 * 3600))).isTrue();
        // El cliente manda 24 h porque la pantalla se quedó abierta: se guardan 4 h como mucho.
        assertThat(s.boundedDurationSeconds(86_400, NOW.plusSeconds(3 * 86_400)))
                .isEqualTo(TrainingSession.MAX_DURATION.toSeconds());
        // Y nunca más que el tiempo real transcurrido.
        assertThat(s.boundedDurationSeconds(3_600, NOW.plusSeconds(1_800))).isEqualTo(1_800);
        assertThat(s.boundedDurationSeconds(1_200, NOW.plusSeconds(3_600))).isEqualTo(1_200);
    }

    @Test
    void sessionCompletionAndUnmarkKeepTheAwardedXp() {
        TrainingSession s = TrainingSession.start(UUID.randomUUID(), null, null, NOW);
        s.recordSet(null, 1, 10, 20.0, true, 0);
        s.complete(89, 8, 123.456, 140, NOW.plusSeconds(3600));
        assertThat(s.durationMinutes()).isEqualTo(1);
        assertThat(s.calories()).isEqualTo(123.5);
        assertThatThrownBy(() -> s.recordSet(null, 2, 10, 20.0, true, 0)).isInstanceOf(SessionAlreadyCompletedException.class);
        TrainingSession.CompletionSnapshot snapshot = s.unmark(LocalDate.of(2026, 10, 5), java.time.ZoneOffset.UTC);
        assertThat(snapshot.xpAwarded()).isEqualTo(140);
        assertThat(snapshot.rpe()).isEqualTo(8);
        assertThat(s.isCompleted()).isFalse();
        assertThat(s.xpAwarded()).isZero();
        assertThatThrownBy(() -> s.complete(60, 11, 0, 0, NOW)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void sessionXpFormula() {
        assertThat(TrainingRewards.sessionXp(45, 7, 0)).isEqualTo(50 + 45 + 35);
        assertThat(TrainingRewards.sessionXp(200, 10, 1)).isEqualTo(50 + 90 + 50);
        assertThat(TrainingRewards.sessionXp(10, 1, 0)).isEqualTo(65);
        // Contra el farmeo: menos de 10 min o más de dos sesiones con XP en el día no puntúan.
        assertThat(TrainingRewards.sessionXp(9, 10, 0)).isZero();
        assertThat(TrainingRewards.sessionXp(45, 7, 2)).isZero();
    }

    @Test
    void caloriesUseMetPerExerciseRestAndScaleToTheSession() {
        PlannedExercise reps = new PlannedExercise(UUID.randomUUID(), REF, P, 1, null);
        ExerciseRef cardio = new ExerciseRef(UUID.randomUUID(), "Remo", null, null, Modality.AEROBIC,
                List.of(MeasurementType.TIME), true, 0, true);
        PlannedExercise timed = new PlannedExercise(UUID.randomUUID(), cardio,
                new ExerciseParameters(1, 1, 30, null, null, 600, null, null), 2, null);
        // Repeticiones: 3 s × 10 × 3 = 90 s a MET 6; descanso 2 × 90 s; cardio 600 s a MET 8 (circuito sin MET).
        double expected = 6.0 * 70 * 90 / 3600 + 1.5 * 70 * 180 / 3600 + 8.0 * 70 * 600 / 3600;
        assertThat(SessionCalories.estimate(List.of(reps, timed), Map.of(), null, 3600)).isCloseTo(expected, within(0.001));
        // Duración real (total del ejercicio) sustituye a la estimación y la sesión limita el total.
        double real = SessionCalories.estimate(List.of(reps), Map.of(reps.id(), 300), 80.0, 150);
        double unscaled = 6.0 * 80 * 300 / 3600 + 1.5 * 80 * 180 / 3600;
        assertThat(real).isCloseTo(unscaled * 150 / 480, within(0.001));
        assertThat(SessionCalories.estimate(List.of(), Map.of(), 80.0, 1800)).isCloseTo(6.0 * 80 * 0.5, within(0.001));
    }

    @Test
    void checkInFatigueScore() {
        DailyCheckIn fresh = DailyCheckIn.create(UUID.randomUUID(), LocalDate.now(),
                new DailyCheckIn.Values(5, 1, 5, 1, List.of(" piernas ", "piernas", ""), true, "  "), NOW);
        assertThat(fresh.fatigueScore()).isEqualTo(5 + 0 + 4 + 0);
        assertThat(fresh.painZones()).containsExactly("piernas");
        assertThat(fresh.notes()).isNull();
        DailyCheckIn tired = DailyCheckIn.create(UUID.randomUUID(), LocalDate.now(),
                new DailyCheckIn.Values(1, 5, 1, 5, List.of(), false, null), NOW);
        assertThat(tired.fatigueScore()).isEqualTo(25 + 20 + 20 + 28);
        assertThat(tired.requiresAdaptation()).isTrue();
        assertThatThrownBy(() -> DailyCheckIn.create(UUID.randomUUID(), LocalDate.now(),
                new DailyCheckIn.Values(0, 1, 1, 1, null, true, null), NOW)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void weeklyPlanNormalizesToMonday() {
        WeeklyTrainingPlan plan = WeeklyTrainingPlan.create(UUID.randomUUID(), LocalDate.of(2026, 10, 11),
                new WeeklyTrainingPlan.Values(3, null, 45, null, null));
        assertThat(plan.weekStart()).isEqualTo(LocalDate.of(2026, 10, 5));
        assertThat(plan.intensity()).isEqualTo(PlanIntensity.MODERATE);
        assertThat(plan.compliance(5)).isEqualTo(1.0);
        assertThatThrownBy(() -> WeeklyTrainingPlan.create(UUID.randomUUID(), LocalDate.now(),
                new WeeklyTrainingPlan.Values(8, null, 45, null, null))).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void defaultWeekTypes() {
        assertThat(WeekType.forPosition(1, 1)).isEqualTo(WeekType.LOAD);
        assertThat(WeekType.forPosition(1, 3)).isEqualTo(WeekType.ADAPTATION);
        assertThat(WeekType.forPosition(3, 3)).isEqualTo(WeekType.PEAK);
        assertThat(WeekType.forPosition(4, 4)).isEqualTo(WeekType.DELOAD);
        assertThat(WeekType.forPosition(2, 4)).isEqualTo(WeekType.LOAD);
        assertThat(TrainingGoal.fromLabelOrDefault("fuerza máxima")).isEqualTo(TrainingGoal.MAX_STRENGTH);
        assertThat(TrainingGoal.fromLabelOrDefault("fuerza")).isEqualTo(TrainingGoal.HYPERTROPHY);
    }
}
