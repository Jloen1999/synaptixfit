package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class ItemTimeStatusTest {

    private static final Instant START = Instant.parse("2026-10-20T16:00:00Z");
    private static final Instant END = START.plusSeconds(3600);

    @Test
    void aTrackedBlockGoesFromUpcomingToMissedUnlessDone() {
        assertThat(ItemTimeStatus.ofBlock(ActivityType.STUDY, START, END, false, START.minusSeconds(1)))
                .isEqualTo(ItemTimeStatus.UPCOMING);
        assertThat(ItemTimeStatus.ofBlock(ActivityType.STUDY, START, END, false, START.plusSeconds(60)))
                .isEqualTo(ItemTimeStatus.IN_PROGRESS);
        assertThat(ItemTimeStatus.ofBlock(ActivityType.SPORT, START, END, false, END.plusSeconds(1)))
                .isEqualTo(ItemTimeStatus.MISSED);
        assertThat(ItemTimeStatus.ofBlock(ActivityType.CLASS, START, END, true, END.plusSeconds(1)))
                .isEqualTo(ItemTimeStatus.DONE);
    }

    @Test
    void untrackedBlocksJustPassAndOverdueDeadlinesAreMissed() {
        assertThat(ItemTimeStatus.ofBlock(ActivityType.SLEEP, START, END, false, END.plusSeconds(1)))
                .isEqualTo(ItemTimeStatus.PAST);
        assertThat(ItemTimeStatus.ofBlock(ActivityType.EXAM, START, END, false, END.plusSeconds(1)))
                .isEqualTo(ItemTimeStatus.PAST);
        assertThat(ItemTimeStatus.ofDeadline(START, false, START.plusSeconds(1))).isEqualTo(ItemTimeStatus.MISSED);
        assertThat(ItemTimeStatus.ofDeadline(START, true, START.plusSeconds(1))).isEqualTo(ItemTimeStatus.DONE);
        assertThat(ItemTimeStatus.ofDeadline(START, false, START.minusSeconds(1))).isEqualTo(ItemTimeStatus.UPCOMING);
    }

    @Test
    void theNextFreeSlotSkipsTheNightAndTheBusyHours() {
        PlannerZone zone = PlannerZone.of("Europe/Madrid");
        java.time.LocalDate day = java.time.LocalDate.of(2026, 10, 20);
        // A las 21:30 un bloque de 60 min ya no cabe hoy (hasta las 22:00): va mañana a las 8:00.
        Instant late = zone.at(day, java.time.LocalTime.of(21, 30));
        Optional<TimeRange> slot = ScheduleConflicts.nextFreeSlot(60, late, zone, List.of());
        assertThat(slot).map(TimeRange::start).contains(zone.at(day.plusDays(1), java.time.LocalTime.of(8, 0)));
    }
}
