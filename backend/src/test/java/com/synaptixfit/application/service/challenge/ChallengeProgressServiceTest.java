package com.synaptixfit.application.service.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.challenge.ChallengeOutcome;
import com.synaptixfit.application.port.input.challenge.RecordChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ReplaceMilestonesUseCase;
import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.exception.challenge.ChallengeNotFoundException;
import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.LinkedDeadline;
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
        return new MilestoneDraft(null, title, Difficulty.LOW, null, null, null, link, List.of(), null, null);
    }

    @Test
    void completeAwardsXpAndPublishesOnlyChallengeCompleted() {
        Challenge c = stored(null, List.of());

        ChallengeOutcome outcome = service.completeChallenge(userId, c.id());

        assertThat(outcome.xpDelta()).isEqualTo(40);
        assertThat(outcome.challengeCompleted()).isTrue();
        assertThat(f.awarded).containsExactly(40);
        assertThat(f.events).singleElement().isInstanceOf(ChallengeCompleted.class);

        service.uncompleteChallenge(userId, c.id());
        assertThat(f.revoked).containsExactly(40);
        assertThat(f.netXp()).isZero();
    }

    @Test
    void linkedChallengeIsNotCompletedByHandAndNeverTouchesTheDeadline() {
        UUID deadline = UUID.randomUUID();
        f.deadlines.put(deadline, new LinkedDeadline("Práctica", NOW.plusSeconds(3600), false));
        Challenge c = stored(new ChallengeLink(LinkType.DELIVERY, deadline), List.of());
        assertThatThrownBy(() -> service.completeChallenge(userId, c.id()))
                .extracting("code").isEqualTo("CHALLENGE_LINKED");
        assertThat(f.events).isEmpty();
    }

    @Test
    void cannotActBeforeTheChallengeStarts() {
        Challenge upcoming = f.repository.save(Challenge.create(UUID.randomUUID(), userId,
                new ChallengeDetails("Reto futuro", null, null, Visibility.PRIVATE, Difficulty.MEDIUM,
                        NOW.plusSeconds(86_400), NOW.plusSeconds(3 * 86_400), null, null),
                List.of(task("Tarea uno", null)), NOW));
        UUID a = upcoming.milestones().getFirst().id();
        assertThatThrownBy(() -> service.completeMilestone(userId, upcoming.id(), a))
                .extracting("code").isEqualTo("CHALLENGE_NOT_STARTED");
        // Antes de empezar sí se pueden preparar las tareas.
        service.replaceMilestones(new ReplaceMilestonesUseCase.Command(userId, upcoming.id(),
                List.of(task("Tarea uno", null), task("Tarea dos", null))));
        assertThat(f.store.get(upcoming.id()).milestones()).hasSize(2);
    }

    @Test
    void linkingADeliveryAlreadyDoneCompletesTheTaskAndCheckingThePeriod() {
        UUID done = UUID.randomUUID();
        UUID late = UUID.randomUUID();
        f.ownedRefs.add(done);
        f.ownedRefs.add(late);
        f.deadlines.put(done, new LinkedDeadline("Práctica 1", NOW.plusSeconds(3600), true));
        f.deadlines.put(late, new LinkedDeadline("Práctica 2", NOW.plusSeconds(30 * 86_400), false));
        Challenge c = stored(null, List.of(task("Tarea libre", null)));

        ChallengeOutcome outcome = service.replaceMilestones(new ReplaceMilestonesUseCase.Command(userId, c.id(),
                List.of(task("Entregar práctica 1", new ChallengeLink(LinkType.DELIVERY, done)))));
        assertThat(outcome.challenge().milestones().getFirst().completed()).isTrue();
        assertThat(outcome.xpDelta()).isEqualTo(20);

        assertThatThrownBy(() -> service.replaceMilestones(new ReplaceMilestonesUseCase.Command(userId, c.id(),
                List.of(task("Entregar práctica 2", new ChallengeLink(LinkType.DELIVERY, late))))))
                .extracting("code").isEqualTo("CHALLENGE_LINK_OUTSIDE_PERIOD");
    }

    @Test
    void absoluteProgressRecordsOnlyWhatWasGained() {
        Challenge c = stored(null, List.of());
        service.recordProgress(new RecordChallengeProgressUseCase.Command(userId, c.id(), null, null, 40.0, null));
        service.recordProgress(new RecordChallengeProgressUseCase.Command(userId, c.id(), null, null, 60.0, null));
        service.recordProgress(new RecordChallengeProgressUseCase.Command(userId, c.id(), null, null, 50.0, null));
        assertThat(f.store.get(c.id()).progress()).isEqualTo(50.0);
        assertThat(f.progress).extracting(p -> p.amount()).containsExactly(40.0, 20.0);
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
    void deadlineSyncIsIdempotentAndOneWay() {
        UUID deadline = UUID.randomUUID();
        UUID otherDeadline = UUID.randomUUID();
        Challenge linked = stored(new ChallengeLink(LinkType.EXAM, deadline), List.of());
        Challenge withTask = stored(null, List.of(task("Tarea vinculada", new ChallengeLink(LinkType.DELIVERY, deadline)),
                task("Tarea libre", null)));
        Challenge other = stored(new ChallengeLink(LinkType.EXAM, otherDeadline), List.of());

        service.syncLinkedEntity(userId, deadline, true);

        assertThat(f.repository.findById(linked.id()).orElseThrow().completed()).isTrue();
        assertThat(f.repository.findById(withTask.id()).orElseThrow().milestones().get(0).completed()).isTrue();
        assertThat(f.repository.findById(other.id()).orElseThrow().completed()).isFalse();
        assertThat(f.netXp()).isEqualTo(40 + 20);

        service.syncLinkedEntity(userId, deadline, true);
        assertThat(f.netXp()).isEqualTo(60);

        service.syncLinkedEntity(userId, deadline, false);
        assertThat(f.netXp()).isZero();
        assertThat(f.repository.findById(linked.id()).orElseThrow().completed()).isFalse();
    }

    @Test
    void routineDayTaskCompletesWhenTrainingThatDayAndReopensWhenUnmarked() {
        UUID routineDay = UUID.randomUUID();
        Challenge withTask = stored(null, List.of(
                task("Entrenar el martes de la semana 2", new ChallengeLink(LinkType.ROUTINE_DAY, routineDay)),
                task("Tarea libre", null)));

        service.syncLinkedEntity(userId, routineDay, true);

        Challenge afterTraining = f.repository.findById(withTask.id()).orElseThrow();
        assertThat(afterTraining.milestones().get(0).completed()).isTrue();
        assertThat(afterTraining.milestones().get(1).completed()).isFalse();
        int xpAfterTraining = f.netXp();
        assertThat(xpAfterTraining).isPositive();

        service.syncLinkedEntity(userId, routineDay, false);

        assertThat(f.repository.findById(withTask.id()).orElseThrow().milestones().get(0).completed()).isFalse();
        assertThat(f.netXp()).isZero();
    }

    @Test
    void deadlineSyncIgnoresOtherUsers() {
        UUID deadline = UUID.randomUUID();
        stored(new ChallengeLink(LinkType.EXAM, deadline), List.of());
        service.syncLinkedEntity(UUID.randomUUID(), deadline, true);
        assertThat(f.awarded).isEmpty();
    }

    @Test
    void studyBlockSyncSetsProgressFromCompletedBlocks() {
        Challenge c = stored(null, List.of(task("Tarea uno", null), task("Tarea dos", null)));
        UUID a = c.milestones().get(0).id();

        f.blocks.put(a, new StudyBlockProgress(4, 2));
        service.syncStudyBlocks(userId, a);
        // Con bloques, la tarea solo avanza por ellos.
        assertThatThrownBy(() -> service.completeMilestone(userId, c.id(), a)).extracting("code")
                .isEqualTo("MILESTONE_LINKED");
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
                new RecordChallengeProgressUseCase.Command(userId, c.id(), a, 100.0, null, null));
        assertThat(outcome.challengeCompleted()).isTrue();
        assertThat(f.progress).hasSize(1);
        assertThat(f.progress.getFirst().recordedAt()).isEqualTo(NOW);
    }

    @Test
    void replaceMilestonesValidatesAttachmentsOwnership() {
        Challenge c = stored(null, List.of());
        UUID note = UUID.randomUUID();
        MilestoneDraft draft = new MilestoneDraft(null, "Con apunte", null, null, note, null, null, List.of(),
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
        assertThatThrownBy(() -> service.replaceMilestones(new ReplaceMilestonesUseCase.Command(userId, expired.id(),
                List.of()))).extracting("code").isEqualTo("CHALLENGE_EXPIRED");
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

        service.syncLinkedEntity(userId, deadline, true);
        service.syncTrainingSessions(userId);

        assertThat(f.store.get(expired.id()).completed()).isFalse();
        assertThat(f.store.get(fitness.id()).completed()).isFalse();
        assertThat(f.awarded).isEmpty();
    }
}
