package com.synaptixfit.application.service.challenge;

import com.synaptixfit.application.port.input.challenge.ChallengeOutcome;
import com.synaptixfit.application.port.input.challenge.CompleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.CompleteMilestoneUseCase;
import com.synaptixfit.application.port.input.challenge.HideUserChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.RecordChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ReorderMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.ReplaceMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncDeadlineChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncMilestoneStudyBlocksUseCase;
import com.synaptixfit.application.port.input.challenge.SyncTrainingSessionChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.UncompleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.UncompleteMilestoneUseCase;
import com.synaptixfit.domain.exception.challenge.ChallengeNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.OptionalDouble;
import java.util.UUID;

/**
 * Estado de los retos y sus tareas: completar, descompletar, progreso, gestión de tareas y
 * sincronización con el planificador, el entrenamiento y la privacidad del usuario (eventos).
 */
public class ChallengeProgressService implements CompleteChallengeUseCase, UncompleteChallengeUseCase,
        ReplaceMilestonesUseCase, ReorderMilestonesUseCase, CompleteMilestoneUseCase, UncompleteMilestoneUseCase,
        RecordChallengeProgressUseCase, SyncDeadlineChallengesUseCase, SyncMilestoneStudyBlocksUseCase,
        SyncTrainingSessionChallengesUseCase, HideUserChallengesUseCase {

    private final ChallengeRepositoryPort challenges;
    private final ChallengeReferencePort referencePort;
    private final ChallengeReferenceValidator references;
    private final ChallengeEffects effects;
    private final Clock clock;
    private final ZoneId zone;
    private final TrainingSessionTracker trainingSessions;

    /**
     * @param zone zona horaria con la que se decide el «día» de la racha de cada reto
     */
    public ChallengeProgressService(ChallengeRepositoryPort challenges, ChallengeReferencePort referencePort,
                                    ChallengeReferenceValidator references, ChallengeEffects effects, Clock clock,
                                    ZoneId zone) {
        this.challenges = challenges;
        this.referencePort = referencePort;
        this.references = references;
        this.effects = effects;
        this.clock = clock;
        this.zone = zone;
        this.trainingSessions = new TrainingSessionTracker(referencePort);
    }

    // ------------------------------------------------------------ acciones del usuario

    @Override
    public ChallengeOutcome completeChallenge(UUID userId, UUID challengeId) {
        Challenge challenge = owned(userId, challengeId);
        return persist(challenge, challenge.complete(today()), null);
    }

    @Override
    public ChallengeOutcome uncompleteChallenge(UUID userId, UUID challengeId) {
        Challenge challenge = owned(userId, challengeId);
        return persist(challenge, challenge.uncomplete(), null);
    }

    @Override
    public ChallengeOutcome replaceMilestones(ReplaceMilestonesUseCase.Command command) {
        Challenge challenge = owned(command.userId(), command.challengeId());
        references.checkDrafts(command.userId(), command.milestones());
        return persist(challenge, challenge.replaceMilestones(command.milestones()), null);
    }

    @Override
    public Challenge reorderMilestones(UUID userId, UUID challengeId, List<UUID> orderedMilestoneIds) {
        Challenge challenge = owned(userId, challengeId);
        challenge.reorderMilestones(orderedMilestoneIds);
        challenge.touch(clock.instant());
        return challenges.save(challenge);
    }

    @Override
    public ChallengeOutcome completeMilestone(UUID userId, UUID challengeId, UUID milestoneId) {
        Challenge challenge = owned(userId, challengeId);
        return persist(challenge, challenge.completeMilestone(milestoneId, today(), false), null);
    }

    @Override
    public ChallengeOutcome uncompleteMilestone(UUID userId, UUID challengeId, UUID milestoneId) {
        Challenge challenge = owned(userId, challengeId);
        return persist(challenge, challenge.uncompleteMilestone(milestoneId), null);
    }

    @Override
    public ChallengeOutcome recordProgress(RecordChallengeProgressUseCase.Command command) {
        Challenge challenge = owned(command.userId(), command.challengeId());
        Instant now = clock.instant();
        Instant recordedAt = command.recordedAt() == null ? now : command.recordedAt();
        ChallengeChanges changes = challenge.addProgress(command.milestoneId(), command.amount(),
                LocalDate.ofInstant(recordedAt, zone));
        ChallengeOutcome outcome = persist(challenge, changes, null);
        challenges.saveProgress(new ProgressEntry(UUID.randomUUID(), challenge.id(), command.milestoneId(),
                command.userId(), command.amount(), recordedAt, now));
        return outcome;
    }

    // ------------------------------------------------------------ sincronización (eventos)

    @Override
    public void syncDeadline(UUID userId, UUID deadlineId, boolean completed) {
        LocalDate today = today();
        for (Challenge challenge : challenges.findByLinkedEntity(userId, deadlineId)) {
            ChallengeChanges changes = new ChallengeChanges();
            if (isDeadlineLink(challenge.link(), deadlineId)) {
                changes.merge(completed ? challenge.complete(today) : challenge.uncomplete());
            }
            for (Milestone m : challenge.milestones()) {
                if (isDeadlineLink(m.link(), deadlineId)) {
                    changes.merge(completed ? challenge.completeMilestone(m.id(), today, true)
                            : challenge.uncompleteMilestone(m.id()));
                }
            }
            persist(challenge, changes, deadlineId);
        }
    }

    @Override
    public void syncStudyBlocks(UUID userId, UUID milestoneId) {
        if (milestoneId == null) {
            return;
        }
        challenges.findByMilestoneId(milestoneId)
                .filter(c -> c.isOwnedBy(userId))
                .ifPresent(challenge -> {
                    StudyBlockProgress blocks = referencePort.studyBlockProgress(userId, milestoneId);
                    OptionalDouble percent = blocks.percent();
                    if (percent.isEmpty()) {
                        return;
                    }
                    ChallengeChanges changes =
                            challenge.applyStudyBlockProgress(milestoneId, percent.getAsDouble(), today());
                    persist(challenge, changes, null);
                });
    }

    @Override
    public void syncTrainingSessions(UUID userId) {
        LocalDate today = today();
        for (Challenge challenge : challenges.findTrainingTrackedByOwner(userId)) {
            int before = challenge.sessionsCompleted();
            ChallengeChanges changes = trainingSessions.apply(challenge, today);
            if (before != challenge.sessionsCompleted() || changes.xpDelta() != 0 || changes.challengeCompleted()
                    || changes.challengeUncompleted()) {
                persist(challenge, changes, null);
            }
        }
    }

    @Override
    public int hideUserChallenges(UUID userId) {
        int hidden = 0;
        for (Challenge challenge : challenges.findNonPrivateByOwner(userId)) {
            if (challenge.hideFromOthers()) {
                challenge.touch(clock.instant());
                challenges.save(challenge);
                hidden++;
            }
        }
        return hidden;
    }

    // ------------------------------------------------------------ apoyo

    private ChallengeOutcome persist(Challenge challenge, ChallengeChanges changes, UUID sourceEntityId) {
        challenge.touch(clock.instant());
        Challenge saved = challenges.save(challenge);
        effects.apply(saved, changes, sourceEntityId);
        return new ChallengeOutcome(saved, changes.xpDelta(), changes.unlockedMilestoneIds(),
                changes.challengeCompleted());
    }

    private static boolean isDeadlineLink(ChallengeLink link, UUID entityId) {
        return link != null && link.type().isDeadline() && link.entityId().equals(entityId);
    }

    private Challenge owned(UUID userId, UUID challengeId) {
        return challenges.findById(challengeId)
                .filter(c -> c.isOwnedBy(userId))
                .orElseThrow(() -> new ChallengeNotFoundException(challengeId));
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
