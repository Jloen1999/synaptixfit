package com.synaptixfit.domain.model.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.dashboard.Dashboard.DayMark;
import com.synaptixfit.domain.model.dashboard.Dashboard.PlanDay;
import com.synaptixfit.domain.model.dashboard.Dashboard.TodayEvent;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas de Inicio del ADR 0059: fila de «Tu día», marcas y frase de «Tu semana» y aula de un evento. */
class HomeAtAGlanceRulesTest {

    private static final Instant NINE = Instant.parse("2026-11-19T09:00:00Z");
    private static final LocalDate DAY = LocalDate.of(2026, 11, 17);

    private static TodayEvent block(String type, Instant start, ItemTimeStatus status, UUID routineDayId) {
        return new TodayEvent(TodayEvent.Kind.BLOCK, UUID.randomUUID(), type, type, start, start.plusSeconds(3600),
                status == ItemTimeStatus.DONE, null, status, routineDayId == null ? null : UUID.randomUUID(),
                routineDayId);
    }

    @Test
    void spotlightPrefersWhatIsHappeningNowIncludingClasses() {
        TodayEvent study = block("estudio", NINE.plusSeconds(7200), ItemTimeStatus.UPCOMING, null);
        TodayEvent lecture = block("clase", NINE, ItemTimeStatus.IN_PROGRESS, null);

        assertThat(TodaySpotlight.of(List.of(study, lecture))).isEqualTo(lecture.id());
    }

    @Test
    void spotlightSkipsRoutineDaysAndDeadlinesAndThenTakesTheNextOne() {
        TodayEvent routine = block("deporte", NINE, ItemTimeStatus.IN_PROGRESS, UUID.randomUUID());
        TodayEvent deadline = new TodayEvent(TodayEvent.Kind.DEADLINE, UUID.randomUUID(), "Práctica", "entrega",
                NINE, null, false, null, ItemTimeStatus.UPCOMING);
        TodayEvent later = block("clase", NINE.plusSeconds(3600), ItemTimeStatus.UPCOMING, null);

        assertThat(TodaySpotlight.of(List.of(routine, deadline, later))).isEqualTo(later.id());
    }

    @Test
    void withNothingLeftTheSpotlightIsTheLatestMissedButNeverAPastClass() {
        TodayEvent missedStudy = block("estudio", NINE, ItemTimeStatus.MISSED, null);
        TodayEvent pastClass = block("clase", NINE.plusSeconds(3600), ItemTimeStatus.MISSED, null);
        TodayEvent done = block("repaso", NINE.plusSeconds(7200), ItemTimeStatus.DONE, null);

        assertThat(TodaySpotlight.of(List.of(missedStudy, pastClass, done))).isEqualTo(missedStudy.id());
        assertThat(TodaySpotlight.of(List.of(pastClass, done))).isNull();
    }

    @Test
    void dayMarksReadWithoutColour() {
        assertThat(new PlanDay(DAY, 0, 0, 0).mark()).isEqualTo(DayMark.NONE);
        assertThat(new PlanDay(DAY, 3, 3, 0).mark()).isEqualTo(DayMark.DONE);
        assertThat(new PlanDay(DAY, 3, 1, 1).mark()).isEqualTo(DayMark.MISSED);
        assertThat(new PlanDay(DAY, 4, 2, 0).mark()).isEqualTo(DayMark.PARTIAL);
        PlanDay ahead = new PlanDay(DAY, 3, 0, 0);
        assertThat(ahead.mark()).isEqualTo(DayMark.PENDING);
        assertThat(ahead.pending()).isEqualTo(3);
        assertThat(new PlanDay(DAY, 4, 1, 1).pending()).isEqualTo(2);
    }

    @Test
    void weekSummarySaysHowTheWeekIsGoing() {
        assertThat(WeekSummary.of(List.of(new PlanDay(DAY, 0, 0, 0))))
                .isEqualTo(new WeekSummary(0, 0, 0, WeekSummary.State.NO_PLAN));
        // 8 de 12 hechas y 2 sin hacer: 2 de las 10 que ya tocaban (20 %), vas bien.
        assertThat(WeekSummary.of(List.of(new PlanDay(DAY, 6, 5, 1), new PlanDay(DAY.plusDays(1), 6, 3, 1))))
                .isEqualTo(new WeekSummary(8, 12, 2, WeekSummary.State.ON_TRACK));
        // 2 de 5 que tocaban se quedaron sin hacer (40 %): vas por detrás.
        assertThat(WeekSummary.of(List.of(new PlanDay(DAY, 8, 3, 2))).state()).isEqualTo(WeekSummary.State.BEHIND);
        // Aún no toca nada: no se puede ir por detrás.
        assertThat(WeekSummary.of(List.of(new PlanDay(DAY, 4, 0, 0))).state()).isEqualTo(WeekSummary.State.ON_TRACK);
    }

    @Test
    void theRoomIsTheEventsOwnOrElseTheSubjectsUsualOne() {
        CalendarBlock own = new CalendarBlock(UUID.randomUUID(), "clase", NINE, NINE.plusSeconds(3600), false,
                "Bases de datos", null, null, null, null, " Aula 2.4 ", "Aula 1.1", " Ana Ruiz ");
        CalendarBlock usual = new CalendarBlock(UUID.randomUUID(), "clase", NINE, NINE.plusSeconds(3600), false,
                "Bases de datos", null, null, null, null, "  ", "Aula 1.1", null);
        CalendarBlock unknown = new CalendarBlock(UUID.randomUUID(), "estudio", NINE, NINE.plusSeconds(3600), false,
                null, null);

        assertThat(own.where()).isEqualTo("Aula 2.4");
        assertThat(own.teacherName()).isEqualTo("Ana Ruiz");
        assertThat(usual.where()).isEqualTo("Aula 1.1");
        assertThat(usual.teacherName()).isNull();
        assertThat(unknown.where()).isNull();
    }
}
