package com.synaptixfit.infrastructure.adapter.input.event.insights;

import com.synaptixfit.application.port.input.insights.InitializeCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.RecordTrainingLoadUseCase;
import com.synaptixfit.application.port.input.insights.RefreshCognitiveStateUseCase;
import com.synaptixfit.domain.event.academic.ReviewCompleted;
import com.synaptixfit.domain.event.academic.TestSessionCompleted;
import com.synaptixfit.domain.event.planner.FocusSessionCompleted;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.event.user.UserRegistered;
import java.util.UUID;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Oyentes de los indicadores: estado inicial, carga física y carga cognitiva (bloques y práctica
 * académica). Solo traducen el evento a un caso de uso; todos son idempotentes (crear si no existe,
 * registro único por sesión, recálculo desde cero del estado cognitivo).
 */
@Component
public class InsightsEventListener {

    private final InitializeCognitiveStateUseCase initializeCognitiveState;
    private final RecordTrainingLoadUseCase recordTrainingLoad;
    private final RefreshCognitiveStateUseCase refreshCognitiveState;

    public InsightsEventListener(InitializeCognitiveStateUseCase initializeCognitiveState,
                                 RecordTrainingLoadUseCase recordTrainingLoad,
                                 RefreshCognitiveStateUseCase refreshCognitiveState) {
        this.initializeCognitiveState = initializeCognitiveState;
        this.recordTrainingLoad = recordTrainingLoad;
        this.refreshCognitiveState = refreshCognitiveState;
    }

    @EventListener
    public void on(UserRegistered event) {
        initializeCognitiveState.initializeCognitiveState(event.userId());
    }

    @EventListener
    public void on(TrainingSessionCompletionChanged event) {
        recordTrainingLoad.recordTrainingLoad(new RecordTrainingLoadUseCase.Command(event.userId(), event.sessionId(),
                event.date(), event.rpe(), event.durationMinutes(), event.completed()));
    }

    @EventListener
    public void on(StudyBlockCompletionChanged event) {
        refreshCognitiveState.refreshCognitiveState(
                new RefreshCognitiveStateUseCase.Command(event.userId(), event.activityType()));
    }

    @EventListener
    public void on(FocusSessionCompleted event) {
        refreshPractice(event.userId());
    }

    @EventListener
    public void on(TestSessionCompleted event) {
        refreshPractice(event.userId());
    }

    @EventListener
    public void on(ReviewCompleted event) {
        refreshPractice(event.userId());
    }

    /** Práctica sin bloque (Pomodoro, test, repaso SM-2): siempre cognitiva, tipo nulo. */
    private void refreshPractice(UUID userId) {
        refreshCognitiveState.refreshCognitiveState(new RefreshCognitiveStateUseCase.Command(userId, null));
    }
}
