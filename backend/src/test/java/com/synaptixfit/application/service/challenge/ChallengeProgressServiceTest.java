package com.synaptixfit.application.service.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.challenge.ChallengeOutcome;
import com.synaptixfit.application.port.input.challenge.RecordChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ReplaceMilestonesUseCase;
import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.event.challenge.ChallengeLinkCompletionChanged;
import com.synaptixfit.domain.exception.challenge.ChallengeNotFoundException;
import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Estado de retos y tareas, XP, eventos y sincronización idempotente con el planificador. */
class ChallengeProgressServiceTest {

    private static final Instant NOW = ChallengeFixtures.CLOCK.instant();
    private final UUID userId = UUID.randomUUID();
    private ChallengeFixtures f;
    private ChallengeProgressService service;

    @BeforeEach
    void setUp() {
        f = new ChallengeFixtures();
        service = new ChallengeProgressService(f.repository, f.references,
                new ChallengeReferenceValidator(f.references), f.effects(), ChallengeFixtures.CLOCK, ZoneOffset.UTC);
    }

    private Challenge stored(ChallengeLink link, List<MilestoneDraft> drafts) {
        Challenge c = Challenge.create(UUID.randomUUID(), userId,
                new ChallengeDetails("Reto de prueba", null, null, Visibility.PUBLIC, Difficulty.MEDIUM, NOW,
                        NOW.plusSeconds(86_400), null, link), drafts, NOW);
        return f.repository.save(c);
    }

    private static MilestoneDraft task(String title, ChallengeLink link) {
        return new MilestoneDraft(null, title, null, Difficulty.LOW, null, null, null, link, List.of(), null, null);
    }

    @Test
    void completeAwardsXpAndPublishesEvents() {
        UUID deadline = UUID.randomUUID();
        Challenge c = stored(new ChallengeLink(LinkType.DELIVERY, deadline), List.of());

        ChallengeOutcome outcome = service.completeChallenge(userId, c.id());

        assertThat(outcome.xpDelta()).isEqualTo(40);
        assertThat(outcome.challengeCompleted()).isTrue();
        assertThat(f.awarded).containsExactly(40);
        assertThat(f.events).hasSize(2);
        assertThat(f.events.get(0)).isInstanceOfSatisfying(ChallengeLinkCompletionChanged.class, e -> {
            assertThat(e.linkedEntityId()).isEqualTo(deadline);
            assertThat(e.linkedEntityType()).isEqualTo("DELIVERY");
            assertThat(e.completed()).isTrue();
        });
        assertThat(f.events.get(1)).isInstanceOf(ChallengeCompleted.class);

        service.uncompleteChallenge(userId, c.id());
        assertThat(f.revoked).containsExactly(40);
        assertThat(f.netXp()).isZero();
    }

    @Test
    void someoneElsesChallengeIsNotFound() {
        Challenge c = stored(null, List.of());
        assertThatThrownBy(() -> service.completeChallenge(UUID.randomUUID(), c.id()))
                .isInstanceOf(ChallengeNotFoundException.class)
                .hasFieldOrPropertyWithValue("code", "CHALLENGE_NOT_FOUND");
    }

    @Test
    void milestoneCompletionCompletesChallengeAndAppliesXp() {
        Challenge c = stored(null, List.of(task("Tarea uno", null), task("Tarea dos", null)));
        UUID a = c.milestones().get(0).id();
        UUID b = c.milestones().get(1).id();

        service.completeMilestone(userId, c.id(), a);
        ChallengeOutcome last = service.completeMilestone(userId, c.id(), b);

        assertThat(last.challengeCompleted()).isTrue();
        assertThat(f.netXp()).isEqualTo(40);
        assertThat(f.events).hasAtLeastOneElementOfType(ChallengeCompleted.class);
    }

    @Test
    void deadlineSyncIsIdempotentAndDoesNotEchoTheSourceDeadline() {
        UUID deadline = UUID.randomUUID();
        UUID otherDeadline = UUID.randomUUID();
        Challenge linked = stored(new ChallengeLink(LinkType.EXAM, deadline), List.of());
        Challenge withTask = stored(null, List.of(task("Tarea vinculada", new ChallengeLink(LinkType.DELIVERY, deadline)),
                task("Tarea libre", null)));
        Challenge other = stored(new ChallengeLink(LinkType.EXAM, otherDeadline), List.of());

        service.syncDeadline(userId, deadline, true);

        assertThat(f.repository.findById(linked.id()).orElseThrow().completed()).isTrue();
        assertThat(f.repository.findById(withTask.id()).orElseThrow().milestones().get(0).completed()).isTrue();
        assertThat(f.repository.findById(other.id()).orElseThrow().completed()).isFalse();
        assertThat(f.netXp()).isEqualTo(40 + 20);
        assertThat(f.events).noneMatch(e -> e instanceof ChallengeLinkCompletionChanged);

        service.syncDeadline(userId, deadline, true);
        assertThat(f.netXp()).isEqualTo(60);

        service.syncDeadline(userId, deadline, false);
        assertThat(f.netXp()).isZero();
        assertThat(f.repository.findById(linked.id()).orElseThrow().completed()).isFalse();
    }

    @Test
    void deadlineSyncIgnoresOtherUsers() {
        UUID deadline = UUID.randomUUID();
        stored(new ChallengeLink(LinkType.EXAM, deadline), List.of());
        service.syncDeadline(UUID.randomUUID(), deadline, true);
        assertThat(f.awarded).isEmpty();
    }

    @Test
    void studyBlockSyncSetsProgressFromCompletedBlocks() {
        Challenge c = stored(null, List.of(task("Tarea uno", null), task("Tarea dos", null)));
        UUID a = c.milestones().get(0).id();

        f.blocks.put(a, new StudyBlockProgress(4, 2));
        service.syncStudyBlocks(userId, a);
        assertThat(f.repository.findById(c.id()).orElseThrow().milestone(a).progress()).isEqualTo(50.0);

        f.blocks.put(a, new StudyBlockProgress(4, 4));
        service.syncStudyBlocks(userId, a);
        service.syncStudyBlocks(userId, a);
        assertThat(f.repository.findById(c.id()).orElseThrow().milestone(a).completed()).isTrue();
        assertThat(f.awarded).containsExactly(20);

        service.syncStudyBlocks(UUID.randomUUID(), a);
        service.syncStudyBlocks(userId, null);
        assertThat(f.awarded).containsExactly(20);
    }

    @Test
    void privacyChangeHidesChallenges() {
        stored(null, List.of());
        stored(null, List.of());
        assertThat(service.hideUserChallenges(userId)).isEqualTo(2);
        assertThat(f.store.values()).allMatch(c -> c.visibility() == Visibility.PRIVATE);
        assertThat(service.hideUserChallenges(userId)).isZero();
    }

    @Test
    void recordProgressSavesEntryAndCompletes() {
        Challenge c = stored(null, List.of(task("Tarea uno", null)));
        UUID a = c.milestones().get(0).id();
        ChallengeOutcome outcome = service.recordProgress(
                new RecordChallengeProgressUseCase.Command(userId, c.id(), a, 100, null));
        assertThat(outcome.challengeCompleted()).isTrue();
        assertThat(f.progress).hasSize(1);
        assertThat(f.progress.getFirst().recordedAt()).isEqualTo(NOW);
    }

    @Test
    void replaceMilestonesValidatesAttachmentsOwnership() {
        Challenge c = stored(null, List.of());
        UUID note = UUID.randomUUID();
        MilestoneDraft draft = new MilestoneDraft(null, "Con apunte", null, null, null, note, null, null, List.of(),
                null, null);
        assertThatThrownBy(() -> service.replaceMilestones(
                new ReplaceMilestonesUseCase.Command(userId, c.id(), List.of(draft))))
                .isInstanceOf(MilestoneAttachmentNotFoundException.class);

        f.ownedRefs.add(note);
        ChallengeOutcome outcome = service.replaceMilestones(
                new ReplaceMilestonesUseCase.Command(userId, c.id(), List.of(draft)));
        assertThat(outcome.challenge().milestones().getFirst().noteId()).isEqualTo(note);
    }

    @Test
    void trainingSessionsCompleteAndUncompleteFitnessChallengesIdempotently() {
        Challenge c = f.repository.save(Challenge.create(UUID.randomUUID(), userId,
                new ChallengeDetails("Entrenar dos veces", ChallengeType.FITNESS, null, Visibility.PRIVATE,
                        Difficulty.LOW, NOW.minusSeconds(3600), NOW.plusSeconds(86_400), null, null, 2), List.of(), NOW));
        f.trainingSessions.add(NOW.minusSeconds(600));
        service.syncTrainingSessions(userId);
        assertThat(f.store.get(c.id()).sessionsCompleted()).isEqualTo(1);
        assertThat(f.events).isEmpty();

        f.trainingSessions.add(NOW);
        service.syncTrainingSessions(userId);
        service.syncTrainingSessions(userId);
        assertThat(f.store.get(c.id()).completed()).isTrue();
        assertThat(f.awarded).containsExactly(Difficulty.LOW.xp());
        assertThat(f.events).filteredOn(ChallengeCompleted.class::isInstance).hasSize(1);

        // Una sesión anterior al reto no cuenta; desmarcar una del periodo lo descompleta.
        f.trainingSessions.removeLast();
        f.trainingSessions.add(NOW.minusSeconds(7200));
        service.syncTrainingSessions(userId);
        assertThat(f.store.get(c.id()).completed()).isFalse();
        assertThat(f.netXp()).isZero();
    }

    @Test
    void anExpiredChallengeNoLongerAdvances() {
        Challenge expired = f.repository.save(Challenge.create(UUID.randomUUID(), userId,
                new ChallengeDetails("Reto vencido", null, null, Visibility.PUBLIC, Difficulty.MEDIUM,
                        NOW.minusSeconds(3 * 86_400), NOW.minusSeconds(3_600), null, null), List.of(), NOW));

        assertThatThrownBy(() -> service.completeChallenge(userId, expired.id()))
                .extracting("code").isEqualTo("CHALLENGE_EXPIRED");
        assertThatThrownBy(() -> service.uncompleteChallenge(userId, expired.id()))
                .extracting("code").isEqualTo("CHALLENGE_EXPIRED");
    }

    @Test
    void synchronisationLeavesExpiredChallengesAsTheyWere() {
        UUID deadline = UUID.randomUUID();
        Challenge expired = f.repository.save(Challenge.create(UUID.randomUUID(), userId,
                new ChallengeDetails("Entrega vencida", null, null, Visibility.PUBLIC, Difficulty.MEDIUM,
                        NOW.minusSeconds(3 * 86_400), NOW.minusSeconds(3_600), null,
                        new ChallengeLink(LinkType.DELIVERY, deadline)), List.of(), NOW));
        Challenge fitness = f.repository.save(Challenge.create(UUID.randomUUID(), userId,
                new ChallengeDetails("Entrenar vencido", ChallengeType.FITNESS, null, Visibility.PRIVATE,
                        Difficulty.LOW, NOW.minusSeconds(3 * 86_400), NOW.minusSeconds(3_600), null, null, 1),
                List.of(), NOW));
        f.trainingSessions.add(NOW.minusSeconds(2 * 86_400));

        service.syncDeadline(userId, deadline, true);
        service.syncTrainingSessions(userId);

        assertThat(f.store.get(expired.id()).completed()).isFalse();
        assertThat(f.store.get(fitness.id()).completed()).isFalse();
        assertThat(f.awarded).isEmpty();
    }
}
