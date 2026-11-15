package com.synaptixfit.infrastructure.adapter.input.event.gamification;

import com.synaptixfit.application.port.input.challenge.HideUserChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncLinkedEntityChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncMilestoneStudyBlocksUseCase;
import com.synaptixfit.application.port.input.challenge.SyncRuleChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncTrainingSessionChallengesUseCase;
import com.synaptixfit.domain.event.academic.ReviewCompleted;
import com.synaptixfit.domain.event.academic.TestSessionCompleted;
import com.synaptixfit.domain.event.planner.FocusSessionCompleted;
import com.synaptixfit.domain.event.planner.WeekPlanChanged;
import com.synaptixfit.domain.event.training.CheckInSubmitted;
import com.synaptixfit.domain.event.training.TrainingSessionCorrected;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.domain.event.planner.StudyBlockAssignmentChanged;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.event.planner.SportBlockCompletionChanged;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.event.user.UserPrivacyChanged;
import com.synaptixfit.domain.model.shared.Visibility;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Reacciones de los retos a eventos del planificador, del entrenamiento, de Académico y de la cuenta. Solo traduce
 * el evento a un caso de uso; los casos de uso son idempotentes. Los retos con regla automática (ADR 0043) se
 * recuentan con todo lo que puede contar en ellos.
 */
@Component
public class ChallengeEventListener {

    private final SyncLinkedEntityChallengesUseCase syncLinked;
    private final SyncMilestoneStudyBlocksUseCase syncStudyBlocks;
    private final SyncTrainingSessionChallengesUseCase syncTrainingSessions;
    private final HideUserChallengesUseCase hideChallenges;
    private final SyncRuleChallengesUseCase syncRules;

    public ChallengeEventListener(SyncLinkedEntityChallengesUseCase syncLinked,
                                  SyncMilestoneStudyBlocksUseCase syncStudyBlocks,
                                  SyncTrainingSessionChallengesUseCase syncTrainingSessions,
                                  HideUserChallengesUseCase hideChallenges,
                                  SyncRuleChallengesUseCase syncRules) {
        this.syncLinked = syncLinked;
        this.syncStudyBlocks = syncStudyBlocks;
        this.syncTrainingSessions = syncTrainingSessions;
        this.hideChallenges = hideChallenges;
        this.syncRules = syncRules;
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
        syncRules.syncRuleChallenges(event.userId());
        // Las tareas vinculadas a ese día de rutina se completan (o se reabren) con él (ADR 0032).
        if (event.routineDayId() != null) {
            syncLinked.syncLinkedEntity(event.userId(), event.routineDayId(), event.completed());
        }
    }

    /** Una carrera o actividad de deporte hecha (o desmarcada) también cuenta en los retos de entrenos. */
    @EventListener
    public void on(SportBlockCompletionChanged event) {
        syncTrainingSessions.syncTrainingSessions(event.userId());
        syncRules.syncRuleChallenges(event.userId());
    }

    @EventListener
    public void on(ReviewCompleted event) {
        syncRules.syncRuleChallenges(event.userId());
    }

    @EventListener
    public void on(TestSessionCompleted event) {
        syncRules.syncRuleChallenges(event.userId());
    }

    @EventListener
    public void on(FocusSessionCompleted event) {
        syncRules.syncRuleChallenges(event.userId());
    }

    @EventListener
    public void on(CheckInSubmitted event) {
        syncRules.syncRuleChallenges(event.userId());
    }

    /** Corregir la duración puede hacer que un entreno pase a contar (o deje de contar) en los retos. */
    @EventListener
    public void on(TrainingSessionCorrected event) {
        syncRules.syncRuleChallenges(event.userId());
    }

    @EventListener
    public void on(WeekPlanChanged event) {
        syncRules.syncRuleChallenges(event.userId());
    }

    @EventListener
    public void on(UserPrivacyChanged event) {
        if (event.newPrivacy() == Visibility.PRIVATE) {
            hideChallenges.hideUserChallenges(event.userId());
        }
    }
}
