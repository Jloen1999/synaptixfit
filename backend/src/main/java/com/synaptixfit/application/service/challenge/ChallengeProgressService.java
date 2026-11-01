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
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.challenge.ChallengeNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.OptionalDouble;
import java.util.Set;
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
    private final LinkedSourcesSync linkedSources;

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
        this.linkedSources = new LinkedSourcesSync(challenges, zone);
    }

    // ------------------------------------------------------------ acciones del usuario

    @Override
    public ChallengeOutcome completeChallenge(UUID userId, UUID challengeId) {
        Challenge challenge = owned(userId, challengeId);
        challenge.requireOpen(clock.instant());
        return persist(challenge, challenge.complete(today()));
    }

    @Override
    public ChallengeOutcome uncompleteChallenge(UUID userId, UUID challengeId) {
        Challenge challenge = owned(userId, challengeId);
        // Desmarcar uno vencido lo dejaría sin poder recompletarse (y sin su XP por un toque).
        challenge.requireOpen(clock.instant());
        return persist(challenge, challenge.uncomplete());
    }

    @Override
    public ChallengeOutcome replaceMilestones(ReplaceMilestonesUseCase.Command command) {
        Challenge challenge = owned(command.userId(), command.challengeId());
        Instant now = clock.instant();
        // Antes de empezar se pueden preparar las tareas; después del fin, no (borrar las pendientes de un
        // reto vencido lo daría por completado).
        challenge.requireNotEnded(now);
        Set<UUID> previousLinks = new HashSet<>();
        challenge.allLinks().forEach(l -> previousLinks.add(l.entityId()));
        references.checkDrafts(command.userId(), command.milestones(), previousLinks);
        List<UUID> newLinks = command.milestones().stream().map(MilestoneDraft::link).filter(Objects::nonNull)
                .map(ChallengeLink::entityId).filter(id -> !previousLinks.contains(id)).toList();
        ChallengeChanges changes = challenge.replaceMilestones(command.milestones());
        challenge.touch(now);
        Challenge saved = linkedSources.apply(challenges.save(challenge), newLinks, changes, now);
        effects.apply(saved, changes);
        return outcome(saved, changes);
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
        challenge.requireOpen(clock.instant());
        return persist(challenge, challenge.completeMilestone(milestoneId, today()));
    }

    @Override
    public ChallengeOutcome uncompleteMilestone(UUID userId, UUID challengeId, UUID milestoneId) {
        Challenge challenge = owned(userId, challengeId);
        // Misma regla que el reto: una tarea de un reto vencido ya no se desmarca (perdería su XP).
        challenge.requireOpen(clock.instant());
        return persist(challenge, challenge.uncompleteMilestone(milestoneId));
    }

    @Override
    public ChallengeOutcome recordProgress(RecordChallengeProgressUseCase.Command command) {
        Challenge challenge = owned(command.userId(), command.challengeId());
        Instant now = clock.instant();
        challenge.requireOpen(now);
        Instant recordedAt = command.recordedAt() == null ? now : command.recordedAt();
        if (!challenge.acceptsProgressAt(recordedAt, now)) {
            throw new FieldValidationException("recordedAt", "OUT_OF_RANGE",
                    "recordedAt must be between the challenge start and now");
        }
        if (command.value() == null && command.amount() == null) {
            throw new FieldValidationException("value", "REQUIRED", "value (or the former amount) is required");
        }
        LocalDate day = LocalDate.ofInstant(recordedAt, zone);
        double before = currentProgress(challenge, command.milestoneId());
        ChallengeChanges changes = command.value() != null
                ? challenge.setProgress(command.milestoneId(), command.value(), day)
                : challenge.addProgress(command.milestoneId(), command.amount(), day);
        double gained = currentProgress(challenge, command.milestoneId()) - before;
        ChallengeOutcome outcome = persist(challenge, changes);
        // El historial guarda lo que se avanzó; bajar el valor es una corrección y no se anota.
        if (gained > 0) {
            challenges.saveProgress(new ProgressEntry(UUID.randomUUID(), challenge.id(), command.milestoneId(),
                    command.userId(), Math.round(gained * 100.0) / 100.0, recordedAt, now));
        }
        return outcome;
    }

    // ------------------------------------------------------------ sincronización (eventos)

    @Override
    public void syncDeadline(UUID userId, UUID deadlineId, boolean completed) {
        LocalDate today = today();
        Instant now = clock.instant();
        for (Challenge challenge : challenges.findByLinkedEntity(userId, deadlineId)) {
            // Un reto vencido queda como estaba; si se amplía, la edición recupera el estado de la entrega.
            if (challenge.status(now) == ChallengeStatus.EXPIRED) {
                continue;
            }
            persist(challenge, challenge.applyDeadline(deadlineId, completed, today));
        }
    }

    @Override
    public void syncStudyBlocks(UUID userId, UUID milestoneId) {
        if (milestoneId == null) {
            return;
        }
        challenges.findByMilestoneId(milestoneId)
                .filter(c -> c.isOwnedBy(userId))
                .filter(c -> c.status(clock.instant()) != ChallengeStatus.EXPIRED)
                .ifPresent(challenge -> {
                    OptionalDouble percent = referencePort.studyBlockProgress(userId, milestoneId).percent();
                    if (percent.isEmpty()) {
                        return;
                    }
                    persist(challenge, challenge.applyStudyBlockProgress(milestoneId, percent.getAsDouble(), today()));
                });
    }

    @Override
    public void syncTrainingSessions(UUID userId) {
        LocalDate today = today();
        Instant now = clock.instant();
        for (Challenge challenge : challenges.findTrainingTrackedByOwner(userId)) {
            if (challenge.status(now) == ChallengeStatus.EXPIRED) {
                continue;
            }
            int before = challenge.sessionsCompleted();
            ChallengeChanges changes = trainingSessions.apply(challenge, today);
            if (before != challenge.sessionsCompleted() || !changes.isEmpty()) {
                persist(challenge, changes);
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

    private ChallengeOutcome persist(Challenge challenge, ChallengeChanges changes) {
        challenge.touch(clock.instant());
        Challenge saved = challenges.save(challenge);
        effects.apply(saved, changes);
        return outcome(saved, changes);
    }

    private static ChallengeOutcome outcome(Challenge saved, ChallengeChanges changes) {
        return new ChallengeOutcome(saved, changes.xpDelta(), changes.unlockedMilestoneIds(),
                changes.challengeCompleted());
    }

    private static double currentProgress(Challenge challenge, UUID milestoneId) {
        if (milestoneId == null) {
            return challenge.completed() ? 100 : challenge.manualProgress();
        }
        return challenge.hasMilestone(milestoneId) ? challenge.milestone(milestoneId).progress() : 0;
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
