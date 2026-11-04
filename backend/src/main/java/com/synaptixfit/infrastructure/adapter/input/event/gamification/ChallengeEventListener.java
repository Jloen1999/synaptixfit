package com.synaptixfit.infrastructure.adapter.input.event.gamification;

import com.synaptixfit.application.port.input.challenge.HideUserChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncLinkedEntityChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncMilestoneStudyBlocksUseCase;
import com.synaptixfit.application.port.input.challenge.SyncTrainingSessionChallengesUseCase;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.domain.event.planner.StudyBlockAssignmentChanged;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.event.user.UserPrivacyChanged;
import com.synaptixfit.domain.model.shared.Visibility;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Reacciones de los retos a eventos del planificador, del entrenamiento y de la cuenta. Solo traduce
 * el evento a un caso de uso; los casos de uso son idempotentes.
 */
@Component
public class ChallengeEventListener {

    private final SyncLinkedEntityChallengesUseCase syncLinked;
    private final SyncMilestoneStudyBlocksUseCase syncStudyBlocks;
    private final SyncTrainingSessionChallengesUseCase syncTrainingSessions;
    private final HideUserChallengesUseCase hideChallenges;

    public ChallengeEventListener(SyncLinkedEntityChallengesUseCase syncLinked,
                                  SyncMilestoneStudyBlocksUseCase syncStudyBlocks,
                                  SyncTrainingSessionChallengesUseCase syncTrainingSessions,
                                  HideUserChallengesUseCase hideChallenges) {
        this.syncLinked = syncLinked;
        this.syncStudyBlocks = syncStudyBlocks;
        this.syncTrainingSessions = syncTrainingSessions;
        this.hideChallenges = hideChallenges;
    }

    @EventListener
    public void on(DeadlineCompletionChanged event) {
        syncLinked.syncLinkedEntity(event.userId(), event.deadlineId(), event.completed());
    }

    @EventListener
    public void on(StudyBlockCompletionChanged event) {
        if (event.challengeMilestoneId() != null) {
            syncStudyBlocks.syncStudyBlocks(event.userId(), event.challengeMilestoneId());
        }
    }

    @EventListener
    public void on(StudyBlockAssignmentChanged event) {
        event.milestoneIds().forEach(id -> syncStudyBlocks.syncStudyBlocks(event.userId(), id));
    }

    @EventListener
    public void on(TrainingSessionCompletionChanged event) {
        syncTrainingSessions.syncTrainingSessions(event.userId());
        // Las tareas vinculadas a ese día de rutina se completan (o se reabren) con él (ADR 0032).
        if (event.routineDayId() != null) {
            syncLinked.syncLinkedEntity(event.userId(), event.routineDayId(), event.completed());
        }
    }

    @EventListener
    public void on(UserPrivacyChanged event) {
        if (event.newPrivacy() == Visibility.PRIVATE) {
            hideChallenges.hideUserChallenges(event.userId());
        }
    }
}
