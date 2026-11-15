package com.synaptixfit.domain.model.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.dashboard.Dashboard.TodayEvent;
import com.synaptixfit.domain.model.dashboard.TodaySummary.State;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Tu día» dice lo mismo que la agenda (ADR 0050): nunca «Has terminado» si queda algo sin hacer. */
class TodaySummaryTest {

    private static final Instant DAY = Instant.parse("2026-11-15T00:00:00Z");

    private static TodayEvent block(ActivityType type, int hour, ItemTimeStatus status) {
        Instant start = DAY.plus(Duration.ofHours(hour));
        return new TodayEvent(TodayEvent.Kind.BLOCK, UUID.randomUUID(), type.code() + hour, type.code(), start,
                start.plus(Duration.ofHours(1)), status == ItemTimeStatus.DONE, null, status);
    }

    private static TodayEvent deadline(int hour, ItemTimeStatus status) {
        return new TodayEvent(TodayEvent.Kind.DEADLINE, UUID.randomUUID(), "Práctica", "entrega",
                DAY.plus(Duration.ofHours(hour)), null, status == ItemTimeStatus.DONE, "Física", status);
    }

    @Test
    void withEverythingDoneTheDayIsDone() {
        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.STUDY, 9, ItemTimeStatus.DONE),
                block(ActivityType.SPORT, 18, ItemTimeStatus.DONE)));

        assertThat(s).isEqualTo(new TodaySummary(2, 2, 0, null, State.ALL_DONE));
    }

    @Test
    void oneDoneAndOneMissedIsNotDone() {
        TodayEvent missed = block(ActivityType.STUDY, 11, ItemTimeStatus.MISSED);

        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.STUDY, 9, ItemTimeStatus.DONE), missed));

        assertThat(s).isEqualTo(new TodaySummary(1, 2, 1, missed.id(), State.MISSED_LEFT));
    }

    @Test
    void withSeveralMissedTheLatestIsHighlighted() {
        TodayEvent latest = block(ActivityType.PERSONAL, 13, ItemTimeStatus.MISSED);

        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.REVIEW, 8, ItemTimeStatus.MISSED), latest));

        assertThat(s.state()).isEqualTo(State.MISSED_LEFT);
        assertThat(s.missed()).isEqualTo(2);
        assertThat(s.nextEventId()).isEqualTo(latest.id());
    }

    @Test
    void whatIsInProgressWinsOverWhatComesAndWhatWasMissed() {
        TodayEvent now = block(ActivityType.STUDY, 12, ItemTimeStatus.IN_PROGRESS);

        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.STUDY, 8, ItemTimeStatus.MISSED),
                block(ActivityType.SPORT, 18, ItemTimeStatus.UPCOMING), now));

        assertThat(s).isEqualTo(new TodaySummary(0, 3, 1, now.id(), State.PENDING));
    }

    @Test
    void withoutAnythingInProgressTheNextOneIsHighlighted() {
        TodayEvent later = block(ActivityType.SPORT, 20, ItemTimeStatus.UPCOMING);
        TodayEvent sooner = block(ActivityType.STUDY, 16, ItemTimeStatus.UPCOMING);

        assertThat(TodaySummary.of(List.of(later, sooner)).nextEventId()).isEqualTo(sooner.id());
    }

    @Test
    void classesDoNotCount() {
        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.CLASS, 9, ItemTimeStatus.MISSED),
                block(ActivityType.CLASS, 11, ItemTimeStatus.UPCOMING)));

        assertThat(s).isEqualTo(new TodaySummary(0, 0, 0, null, State.NOTHING_PLANNED));
    }

    @Test
    void untrackedPastEventsDoNotCount() {
        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.MEAL, 14, ItemTimeStatus.PAST),
                block(ActivityType.REST, 15, ItemTimeStatus.PAST)));

        assertThat(s.state()).isEqualTo(State.NOTHING_PLANNED);
        assertThat(s.total()).isZero();
    }

    @Test
    void todaysDeadlinesCount() {
        TodayEvent due = deadline(23, ItemTimeStatus.UPCOMING);

        TodaySummary s = TodaySummary.of(List.of(block(ActivityType.STUDY, 9, ItemTimeStatus.DONE), due));

        assertThat(s).isEqualTo(new TodaySummary(1, 2, 0, due.id(), State.PENDING));
    }

    @Test
    void anOverdueDeadlineOfTodayIsLeftUndone() {
        TodayEvent overdue = deadline(9, ItemTimeStatus.MISSED);

        TodaySummary s = TodaySummary.of(List.of(overdue));

        assertThat(s).isEqualTo(new TodaySummary(0, 1, 1, overdue.id(), State.MISSED_LEFT));
    }

    @Test
    void withNothingPlannedThereIsNothingToSay() {
        assertThat(TodaySummary.of(List.of())).isEqualTo(new TodaySummary(0, 0, 0, null, State.NOTHING_PLANNED));
    }
}
