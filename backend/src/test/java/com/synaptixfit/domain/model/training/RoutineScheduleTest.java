package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Regla única del «próximo día»: orden, días vacíos, sesiones abandonadas, fecha prevista y retraso. */
class RoutineScheduleTest {

    /** Miércoles 7 de octubre de 2026. */
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 7);
    private static final Instant NOW = Instant.parse("2026-10-07T10:00:00Z");
    private static final ExerciseRef REF = new ExerciseRef(UUID.randomUUID(), "Press", null, null, Modality.STRENGTH,
            List.of(MeasurementType.REPETITIONS), false, 6.0, true);
    private static final ExerciseParameters P = new ExerciseParameters(3, 10, 90, null, null, null, null, null);

    private static RoutineDay day(int number, boolean withExercises) {
        RoutineDay d = RoutineDay.create(number, null);
        if (withExercises) {
            d.addExercise(REF, P);
        }
        return d;
    }

    private static Routine routine(LocalDate startDate, List<RoutineDay> week1, List<RoutineDay> week2) {
        return Routine.create(UUID.randomUUID(), "Rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                startDate, null, List.of(RoutineWeek.create(1, null, null, week1),
                        RoutineWeek.create(2, null, null, week2)), NOW);
    }

    @Test
    void notStartedRoutineProposesTheNextPreferredWeekdayFromTodayAndSkipsEmptyDays() {
        RoutineDay empty = day(1, false);
        RoutineDay friday = day(5, true);
        Routine r = routine(null, List.of(empty, friday), List.of(day(1, true)));

        PendingDay next = r.nextPendingDay(RoutineSchedule.Context.of(TODAY, NOW)).orElseThrow();

        assertThat(next.day().id()).isEqualTo(friday.id());
        assertThat(next.status()).isEqualTo(ProgressStatus.PENDING);
        assertThat(next.scheduledDate()).isEqualTo(LocalDate.of(2026, 10, 9));
        assertThat(next.overdue()).isFalse();
        assertThat(next.sessionOfWeek()).isEqualTo(1);
        assertThat(next.sessionsInWeek()).isEqualTo(1);
    }

    @Test
    void afterTheLastProgressTheNextDayIsOverdueWhenItsWeekdayAlreadyPassed() {
        RoutineDay monday = day(1, true);
        RoutineDay tuesday = day(2, true);
        RoutineDay thursday = day(4, true);
        Routine r = routine(null, List.of(monday, tuesday, thursday), List.of(day(1, true)));
        // Lunes 28 sep hecho; el martes 29 tocaba el siguiente y no se hizo.
        r.completeDay(monday.id(), LocalDate.of(2026, 9, 28));

        PendingDay next = r.nextPendingDay(RoutineSchedule.Context.of(TODAY, NOW)).orElseThrow();

        assertThat(next.day().id()).isEqualTo(tuesday.id());
        assertThat(next.scheduledDate()).isEqualTo(LocalDate.of(2026, 9, 29));
        assertThat(next.overdue()).isTrue();
        assertThat(next.sessionOfWeek()).isEqualTo(2);
        assertThat(next.sessionsInWeek()).isEqualTo(3);
    }

    @Test
    void aPlannedBlockAfterTheLastProgressSetsTheDate() {
        RoutineDay monday = day(1, true);
        Routine r = routine(null, List.of(monday), List.of(day(1, true)));
        LocalDate planned = LocalDate.of(2026, 10, 10);

        PendingDay next = r.nextPendingDay(new RoutineSchedule.Context(TODAY, NOW, Map.of(),
                Map.of(monday.id(), List.of(planned)))).orElseThrow();

        assertThat(next.scheduledDate()).isEqualTo(planned);
        assertThat(next.overdue()).isFalse();
    }

    @Test
    void anActiveSessionWinsAndAnAbandonedOneCountsAsPendingWithItsId() {
        RoutineDay monday = day(1, true);
        RoutineDay wednesday = day(3, true);
        Routine r = routine(null, List.of(monday, wednesday), List.of(day(1, true)));
        UUID activeId = UUID.randomUUID();

        PendingDay active = r.nextPendingDay(new RoutineSchedule.Context(TODAY, NOW,
                Map.of(wednesday.id(), new RoutineSchedule.OpenSession(activeId, NOW.minusSeconds(600))), Map.of()))
                .orElseThrow();
        assertThat(active.day().id()).isEqualTo(wednesday.id());
        assertThat(active.status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        assertThat(active.scheduledDate()).isEqualTo(TODAY);

        UUID staleId = UUID.randomUUID();
        r.startDay(monday.id(), TODAY.minusDays(2));
        PendingDay stale = r.nextPendingDay(new RoutineSchedule.Context(TODAY, NOW,
                Map.of(monday.id(), new RoutineSchedule.OpenSession(staleId, NOW.minus(Duration.ofDays(2)))),
                Map.of())).orElseThrow();
        assertThat(stale.day().id()).isEqualTo(monday.id());
        assertThat(stale.status()).isEqualTo(ProgressStatus.PENDING);
        assertThat(stale.staleSessionId()).isEqualTo(staleId);
    }

    @Test
    void nothingLeftMeansNoNextDay() {
        RoutineDay monday = day(1, true);
        RoutineDay week2 = day(1, true);
        Routine r = routine(null, List.of(monday), List.of(week2));
        r.skipDay(monday.id(), TODAY);
        r.completeDay(week2.id(), TODAY);
        assertThat(r.nextPendingDay(RoutineSchedule.Context.of(TODAY, NOW))).isEmpty();
    }

    @Test
    void nextWeekdayWrapsAroundTheWeek() {
        assertThat(RoutineSchedule.nextWeekday(TODAY, 3)).isEqualTo(TODAY);
        assertThat(RoutineSchedule.nextWeekday(TODAY, 1)).isEqualTo(LocalDate.of(2026, 10, 12));
    }
}
