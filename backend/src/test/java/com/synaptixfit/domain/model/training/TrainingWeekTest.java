package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.TrainingWeek.DayState;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** La semana de entreno de un vistazo (ADR 0055): hechos, previstos, hoy y el «2 de 4». */
class TrainingWeekTest {

    /** Miércoles 7 de octubre de 2026; la semana va del lunes 5 al domingo 11. */
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 7);
    private static final ZoneId UTC = ZoneOffset.UTC;

    @Test
    void doneDaysPlannedDaysAndTodayFromMondayToSunday() {
        UUID monday = UUID.randomUUID();
        TrainingWeek week = TrainingWeek.of(TODAY, UTC, Map.of(monday, Instant.parse("2026-10-05T18:00:00Z")),
                List.of(TODAY, LocalDate.of(2026, 10, 9)));

        assertThat(week.monday()).isEqualTo(LocalDate.of(2026, 10, 5));
        assertThat(week.days()).extracting(TrainingWeek.Day::state).containsExactly(DayState.DONE, DayState.FREE,
                DayState.PLANNED, DayState.FREE, DayState.PLANNED, DayState.FREE, DayState.FREE);
        assertThat(week.days().get(0).sessionId()).isEqualTo(monday);
        assertThat(week.days()).filteredOn(TrainingWeek.Day::today).extracting(TrainingWeek.Day::date)
                .containsExactly(TODAY);
        assertThat(week.done()).isEqualTo(1);
        assertThat(week.total()).isEqualTo(3);
    }

    @Test
    void aDayAlreadyTrainedIsDoneEvenIfItWasPlannedAndPastPlansDoNotCount() {
        TrainingWeek week = TrainingWeek.of(TODAY, UTC, Map.of(UUID.randomUUID(), Instant.parse("2026-10-07T09:00:00Z")),
                List.of(LocalDate.of(2026, 10, 6), TODAY));

        assertThat(week.days().get(1).state()).isEqualTo(DayState.FREE);
        assertThat(week.days().get(2).state()).isEqualTo(DayState.DONE);
        assertThat(week.done()).isEqualTo(1);
        assertThat(week.total()).isEqualTo(1);
    }

    @Test
    void withoutRoutineOrSessionsEveryDayIsFree() {
        TrainingWeek week = TrainingWeek.of(TODAY, UTC, Map.of(), List.of());

        assertThat(week.days()).hasSize(7).allMatch(d -> d.state() == DayState.FREE);
        assertThat(week.total()).isZero();
    }

    @Test
    void twoWorkoutsTheSameDayOpenTheLastOne() {
        UUID morning = UUID.randomUUID();
        UUID evening = UUID.randomUUID();
        TrainingWeek week = TrainingWeek.of(TODAY, UTC, Map.of(evening, Instant.parse("2026-10-06T19:00:00Z"),
                morning, Instant.parse("2026-10-06T08:00:00Z")), List.of());

        assertThat(week.days().get(1).sessionId()).isEqualTo(evening);
        assertThat(week.done()).isEqualTo(1);
    }

    @Test
    void eachWorkoutCountsOnItsLocalDay() {
        // Domingo 4 a las 23:30 UTC ya es lunes 5 en Madrid: cuenta en esta semana, el lunes.
        UUID late = UUID.randomUUID();
        TrainingWeek week = TrainingWeek.of(TODAY, ZoneId.of("Europe/Madrid"),
                Map.of(late, Instant.parse("2026-10-04T23:30:00Z")), List.of());

        assertThat(week.days().get(0).sessionId()).isEqualTo(late);
    }
}
