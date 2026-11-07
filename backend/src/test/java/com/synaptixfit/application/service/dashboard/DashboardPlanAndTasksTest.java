package com.synaptixfit.application.service.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.challenge.MilestoneStatus;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Tu semana» con los tres estados y las tareas de reto que adelanta cada evento de hoy (ADR 0035). */
class DashboardPlanAndTasksTest {

    private static final ZoneId UTC = ZoneId.of("UTC");
    private static final LocalDate MONDAY = LocalDate.of(2026, 10, 19);

    private static CalendarBlock block(String type, String start, boolean done) {
        Instant s = Instant.parse(start);
        return new CalendarBlock(UUID.randomUUID(), type, s, s.plusSeconds(3600), done, null, "Dentista");
    }

    @Test
    void personalEventsCountInTheWeekAndRestDoesNot() {
        Instant now = Instant.parse("2026-10-19T20:00:00Z");
        List<Dashboard.PlanDay> days = DashboardService.planWeek(MONDAY, List.of(
                block("personal", "2026-10-19T09:00:00Z", true),
                block("personal", "2026-10-19T11:00:00Z", false),
                block("estudio", "2026-10-19T21:00:00Z", false),
                block("descanso", "2026-10-19T15:00:00Z", false)), UTC, now);

        // Por hacer = planificado − hecho − sin hacer.
        assertThat(days.get(0)).isEqualTo(new Dashboard.PlanDay(MONDAY, 3, 1, 1));
    }

    @Test
    void eachEventSaysWhichChallengeTaskItAdvancesEvenOnceDone() {
        Instant now = Instant.parse("2026-10-19T12:00:00Z");
        UUID deadline = UUID.randomUUID();
        Milestone review = new Milestone(UUID.randomUUID(), "Repasar tema 3", 50, 0, 0, false,
                MilestoneStatus.IN_PROGRESS, List.of(), null, 1, null, null, null, 0, null, null);
        Milestone deliver = new Milestone(UUID.randomUUID(), "Entregar práctica", 50, 1, 0, false,
                MilestoneStatus.AVAILABLE, List.of(), null, 1, null, null,
                new ChallengeLink(LinkType.DELIVERY, deadline), 0, null, null);
        Challenge challenge = Challenge.builder().id(UUID.randomUUID()).ownerId(UUID.randomUUID())
                .title("Aprobar Física").type(ChallengeType.ACADEMIC).startAt(now.minusSeconds(86400))
                .endAt(now.plusSeconds(864000)).createdAt(now).milestones(List.of(review, deliver)).build();
        // Dos eventos de la misma tarea hoy, uno ya hecho: los dos lo dicen.
        CalendarBlock morning = new CalendarBlock(UUID.randomUUID(), "estudio", now.minusSeconds(10800),
                now.minusSeconds(7200), true, null, null, null, null, review.id());
        CalendarBlock evening = new CalendarBlock(UUID.randomUUID(), "estudio", now.plusSeconds(18000),
                now.plusSeconds(21600), false, null, null, null, null, review.id());
        List<Dashboard.TodayEvent> events = List.of(event(morning), event(evening),
                new Dashboard.TodayEvent(Dashboard.TodayEvent.Kind.DEADLINE, deadline, "Práctica 2", "entrega",
                        now.plusSeconds(36000), null, false, null, ItemTimeStatus.UPCOMING));

        List<Dashboard.TodayEvent> withTasks = DashboardService.withTasks(events, List.of(morning, evening),
                List.of(challenge));

        assertThat(withTasks).extracting(e -> e.tasks().getFirst().title())
                .containsExactly("Repasar tema 3", "Repasar tema 3", "Entregar práctica");
        assertThat(withTasks.getFirst().tasks().getFirst().challengeTitle()).isEqualTo("Aprobar Física");
    }

    private static Dashboard.TodayEvent event(CalendarBlock b) {
        return new Dashboard.TodayEvent(Dashboard.TodayEvent.Kind.BLOCK, b.id(), "Física", b.activityType(),
                b.start(), b.end(), b.completed(), null, ItemTimeStatus.UPCOMING);
    }
}
