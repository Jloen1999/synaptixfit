package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Plan por fases (semana actual, avance, fechas y siguiente paso), plantillas y evolución de un ejercicio. */
class RoutinePlanAndProgressTest {

    private static final Instant NOW = Instant.parse("2026-11-02T10:00:00Z");
    private static final ExerciseRef REF = new ExerciseRef(UUID.randomUUID(), "Press", null, null, Modality.STRENGTH,
            List.of(MeasurementType.REPETITIONS), false, 6.0, true);
    private static final ExerciseParameters P = new ExerciseParameters(3, 10, 90, null, null, null, null, null);
    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");

    private static Routine routine(int weeks, LocalDate start) {
        List<RoutineWeek> list = new ArrayList<>();
        for (int w = 1; w <= weeks; w++) {
            RoutineDay monday = RoutineDay.create(1, null);
            monday.addExercise(REF, P);
            RoutineDay thursday = RoutineDay.create(4, null);
            thursday.addExercise(REF, P);
            list.add(RoutineWeek.create(w, null, null, List.of(monday, thursday)));
        }
        return Routine.create(UUID.randomUUID(), "Rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY, start,
                null, list, NOW);
    }

    @Test
    void currentWeekIsTheOneOfTheNextDayAndProgressCountsClosedDays() {
        Routine r = routine(4, LocalDate.of(2026, 11, 2));
        RoutineWeek first = r.weeks().getFirst();
        r.completeDay(first.days().get(0).id(), LocalDate.of(2026, 11, 2));
        r.completeDay(first.days().get(1).id(), LocalDate.of(2026, 11, 5));

        RoutinePlan plan = RoutinePlan.of(r);

        assertThat(plan.currentWeek()).isEqualTo(2);
        assertThat(plan.totalWeeks()).isEqualTo(4);
        assertThat(plan.percentDone()).isEqualTo(25);
        assertThat(plan.datesOf(2).startsOn()).isEqualTo(LocalDate.of(2026, 11, 9));
        assertThat(plan.datesOf(2).endsOn()).isEqualTo(LocalDate.of(2026, 11, 15));
        assertThat(plan.nextStep()).isEqualTo(RoutinePlan.NextStep.REPEAT_STRONGER);
    }

    @Test
    void withoutStartDateThereAreNoDatesAndLongPlansSuggestANewOne() {
        RoutinePlan plan = RoutinePlan.of(routine(8, null));

        assertThat(plan.currentWeek()).isEqualTo(1);
        assertThat(plan.percentDone()).isZero();
        assertThat(plan.datesOf(1).startsOn()).isNull();
        assertThat(plan.nextStep()).isEqualTo(RoutinePlan.NextStep.NEW_PLAN);
    }

    @Test
    void easyWeekOfATemplateDropsOneSetButNeverBelowOne() {
        RoutineTemplate.Item item = new RoutineTemplate.Item(UUID.randomUUID(), 3, 10, 90, null);
        RoutineTemplate.Item single = new RoutineTemplate.Item(UUID.randomUUID(), 1, 1, 60, 30);

        assertThat(RoutineTemplate.parametersFor(item, WeekType.LOAD).sets()).isEqualTo(3);
        assertThat(RoutineTemplate.parametersFor(item, WeekType.DELOAD).sets()).isEqualTo(2);
        assertThat(RoutineTemplate.parametersFor(single, WeekType.DELOAD).sets()).isEqualTo(1);
        assertThat(RoutineTemplate.parametersFor(single, WeekType.DELOAD).isometricSeconds()).isEqualTo(30);
    }

    private static PerformedSet set(UUID exercise, Integer reps, Double kg, boolean warmup) {
        return new PerformedSet(exercise, "Press", new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, reps, kg,
                true, 0, null, null, exercise, null, warmup, false));
    }

    @Test
    void progressKeepsTheBestEstimatePerDayAndIgnoresWarmupsBodyweightAndLongSets() {
        UUID bench = UUID.randomUUID();
        UUID other = UUID.randomUUID();
        List<CompletedSessionSummary> sessions = List.of(
                new CompletedSessionSummary(UUID.randomUUID(), Instant.parse("2026-10-01T18:00:00Z"), 7, 60,
                        List.of(set(bench, 8, 60.0, false), set(bench, 5, 70.0, false), set(bench, 10, 100.0, true),
                                set(other, 5, 200.0, false))),
                new CompletedSessionSummary(UUID.randomUUID(), Instant.parse("2026-10-08T18:00:00Z"), 7, 60,
                        List.of(set(bench, 20, 40.0, false), set(bench, 10, null, false))),
                new CompletedSessionSummary(UUID.randomUUID(), Instant.parse("2026-10-15T18:00:00Z"), 7, 60,
                        List.of(set(bench, 6, 72.5, false))));

        List<ExerciseProgress.Point> points = ExerciseProgress.of(bench, sessions, ZONE);

        assertThat(points).extracting(ExerciseProgress.Point::date)
                .containsExactly(LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 15));
        assertThat(points.getFirst().weightKg()).isIn(60.0, 70.0);
        assertThat(points.getFirst().estimatedMaxKg()).isGreaterThan(70.0);
        assertThat(points.getLast().estimatedMaxKg()).isGreaterThan(points.getFirst().estimatedMaxKg());
    }

    @Test
    void aFinishedPlanHasNoCurrentWeek() {
        Routine r = routine(1, LocalDate.of(2026, 11, 2));
        r.weeks().getFirst().trainableDays().forEach(d -> r.completeDay(d.id(), LocalDate.of(2026, 11, 3)));

        RoutinePlan plan = RoutinePlan.of(r);

        assertThat(plan.currentWeek()).isNull();
        assertThat(plan.percentDone()).isEqualTo(100);
    }
}
