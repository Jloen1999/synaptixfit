package com.synaptixfit.infrastructure.adapter.input.event.planner;

import com.synaptixfit.application.port.input.planner.CompleteReviewBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteSubjectBlocksUseCase;
import com.synaptixfit.application.port.input.planner.PrivatizeUserStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.SyncSportBlockWithSessionUseCase;
import com.synaptixfit.domain.event.academic.ReviewCompleted;
import com.synaptixfit.domain.event.academic.SubjectDeleted;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.event.user.UserPrivacyChanged;
import com.synaptixfit.domain.model.shared.Visibility;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Reacciones del calendario a otros módulos: el bloque de deporte sigue a la sesión de su día de
 * rutina, el bloque de repaso se completa con el repaso SM-2, los bloques de una asignatura borrada
 * se eliminan por el planificador y los planes pasan a privados con el perfil. Solo traduce el
 * evento al caso de uso; todos son idempotentes.
 */
@Component
public class PlannerSyncListener {

    private final SyncSportBlockWithSessionUseCase syncSportBlock;
    private final CompleteReviewBlockUseCase completeReviewBlock;
    private final DeleteSubjectBlocksUseCase deleteSubjectBlocks;
    private final PrivatizeUserStudyPlansUseCase privatizePlans;

    public PlannerSyncListener(SyncSportBlockWithSessionUseCase syncSportBlock,
                               CompleteReviewBlockUseCase completeReviewBlock,
                               DeleteSubjectBlocksUseCase deleteSubjectBlocks,
                               PrivatizeUserStudyPlansUseCase privatizePlans) {
        this.syncSportBlock = syncSportBlock;
        this.completeReviewBlock = completeReviewBlock;
        this.deleteSubjectBlocks = deleteSubjectBlocks;
        this.privatizePlans = privatizePlans;
    }

    @EventListener
    public void on(TrainingSessionCompletionChanged event) {
        if (event.routineDayId() != null) {
            syncSportBlock.syncSportBlock(event.userId(), event.routineDayId(), event.date(), event.completed());
        }
    }

    @EventListener
    public void on(ReviewCompleted event) {
        completeReviewBlock.completeReviewBlock(event.userId(), event.studyMaterialId());
    }

    @EventListener
    public void on(SubjectDeleted event) {
        deleteSubjectBlocks.deleteSubjectBlocks(event.userId(), event.subjectId());
    }

    @EventListener
    public void on(UserPrivacyChanged event) {
        if (event.newPrivacy() == Visibility.PRIVATE) {
            privatizePlans.privatizeAll(event.userId());
        }
    }
}
