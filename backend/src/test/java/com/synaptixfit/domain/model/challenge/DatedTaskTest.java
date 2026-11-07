package com.synaptixfit.domain.model.challenge;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** De dónde saca su fecha una tarea de reto (ADR 0035). */
class DatedTaskTest {

    private static final Instant NOW = Instant.parse("2026-10-21T08:00:00Z");
    private static final UUID USER = UUID.randomUUID();

    private static Milestone milestone(String title, ChallengeLink link, MilestoneStatus status) {
        return new Milestone(UUID.nameUUIDFromBytes(title.getBytes()), title, 50, 0, 0, false, status, List.of(),
                null, 1, null, null, link, 0, null, null);
    }

    private static Challenge challenge(List<Milestone> milestones, Map<UUID, LinkedDeadline> deadlines,
                                       ChallengeLink link) {
        return Challenge.builder().id(UUID.randomUUID()).ownerId(USER).title("Aprobar Física")
                .type(ChallengeType.ACADEMIC).startAt(NOW.minus(Duration.ofDays(5)))
                .endAt(NOW.plus(Duration.ofDays(20))).createdAt(NOW).milestones(milestones).linkedDeadlines(deadlines)
                .link(link).build();
    }

    @Test
    void aTaskLinkedToADeadlineTakesItsDueDate() {
        UUID deadline = UUID.randomUUID();
        Instant due = NOW.plus(Duration.ofDays(3));
        Challenge c = challenge(List.of(milestone("Entregar práctica",
                        new ChallengeLink(LinkType.DELIVERY, deadline), MilestoneStatus.AVAILABLE)),
                Map.of(deadline, new LinkedDeadline("Práctica 2", due, false)), null);

        assertThat(DatedTask.of(List.of(c), List.of(), null, NOW)).singleElement().satisfies(t -> {
            assertThat(t.anchor()).isEqualTo(DatedTask.Anchor.DEADLINE);
            assertThat(t.anchorId()).isEqualTo(deadline);
            assertThat(t.at()).isEqualTo(due);
            assertThat(t.challengeTitle()).isEqualTo("Aprobar Física");
        });
    }

    @Test
    void aTaskWithEventsTakesTheNextOneNotDone() {
        Milestone m = milestone("Repasar tema 3", null, MilestoneStatus.IN_PROGRESS);
        UUID next = UUID.randomUUID();
        List<DatedTask.EventRef> events = List.of(
                new DatedTask.EventRef(UUID.randomUUID(), m.id(), null, NOW.minus(Duration.ofDays(1)), false),
                new DatedTask.EventRef(UUID.randomUUID(), m.id(), null, NOW.plus(Duration.ofHours(2)), true),
                new DatedTask.EventRef(next, m.id(), null, NOW.plus(Duration.ofDays(1)), false),
                new DatedTask.EventRef(UUID.randomUUID(), m.id(), null, NOW.plus(Duration.ofDays(2)), false));

        assertThat(DatedTask.of(List.of(challenge(List.of(m), Map.of(), null)), events, null, NOW))
                .singleElement().satisfies(t -> {
                    assertThat(t.anchor()).isEqualTo(DatedTask.Anchor.EVENT);
                    assertThat(t.anchorId()).isEqualTo(next);
                });
    }

    @Test
    void aRoutineDayTaskUsesItsTrainingEventOrElseTheExpectedDay() {
        UUID day = UUID.randomUUID();
        Milestone m = milestone("Pierna", new ChallengeLink(LinkType.ROUTINE_DAY, day), MilestoneStatus.AVAILABLE);
        Challenge c = challenge(List.of(m), Map.of(), null);
        Instant dayStart = Instant.parse("2026-10-22T22:00:00Z");

        assertThat(DatedTask.of(List.of(c), List.of(), new DatedTask.RoutineDayRef(day, dayStart), NOW))
                .singleElement().satisfies(t -> {
                    assertThat(t.anchor()).isEqualTo(DatedTask.Anchor.ROUTINE_DAY);
                    assertThat(t.at()).isEqualTo(dayStart);
                });
        UUID event = UUID.randomUUID();
        assertThat(DatedTask.of(List.of(c), List.of(new DatedTask.EventRef(event, null, day,
                        NOW.plus(Duration.ofHours(5)), false)), new DatedTask.RoutineDayRef(day, dayStart), NOW))
                .singleElement().satisfies(t -> assertThat(t.anchorId()).isEqualTo(event));
    }

    @Test
    void doneLockedOrUndatedTasksAreLeftOut() {
        UUID deadline = UUID.randomUUID();
        Challenge c = challenge(List.of(
                        milestone("Sin fecha", null, MilestoneStatus.AVAILABLE),
                        milestone("Bloqueada", new ChallengeLink(LinkType.EXAM, deadline), MilestoneStatus.LOCKED),
                        milestone("Entrega hecha", new ChallengeLink(LinkType.EXAM, deadline),
                                MilestoneStatus.AVAILABLE)),
                Map.of(deadline, new LinkedDeadline("Parcial", NOW.plus(Duration.ofDays(1)), true)), null);

        assertThat(DatedTask.of(List.of(c), List.of(), null, NOW)).isEmpty();
    }

    @Test
    void aChallengeWithoutTasksCompletedByItsDeadlineCountsAsOne() {
        UUID deadline = UUID.randomUUID();
        Challenge c = challenge(List.of(), Map.of(deadline, new LinkedDeadline("Parcial",
                NOW.plus(Duration.ofDays(2)), false)), new ChallengeLink(LinkType.EXAM, deadline));

        assertThat(DatedTask.of(List.of(c), List.of(), null, NOW)).singleElement().satisfies(t -> {
            assertThat(t.title()).isNull();
            assertThat(t.milestoneId()).isNull();
            assertThat(t.anchorId()).isEqualTo(deadline);
        });
    }
}
