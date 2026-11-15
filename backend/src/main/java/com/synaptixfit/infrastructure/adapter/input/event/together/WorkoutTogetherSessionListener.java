package com.synaptixfit.infrastructure.adapter.input.event.together;

import com.synaptixfit.application.port.input.together.NotifyWorkoutTogetherProgressUseCase;
import com.synaptixfit.application.port.input.together.PauseWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.ResumeWorkoutTogetherUseCase;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.event.training.TrainingSessionPauseChanged;
import com.synaptixfit.domain.event.training.TrainingSessionProgressed;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Lo que pasa en la sesión de una persona y afecta a su entreno juntos (ADR 0047): pausar o reanudar pausa o reanuda al
 * grupo; apuntar una serie o terminar se avisa en directo. Síncrono y en la misma transacción; los casos de uso son
 * idempotentes y no hacen nada si la sesión no es de entrenar juntos.
 */
@Component
public class WorkoutTogetherSessionListener {

    private final PauseWorkoutTogetherUseCase pause;
    private final ResumeWorkoutTogetherUseCase resume;
    private final NotifyWorkoutTogetherProgressUseCase progress;

    public WorkoutTogetherSessionListener(PauseWorkoutTogetherUseCase pause, ResumeWorkoutTogetherUseCase resume,
                                          NotifyWorkoutTogetherProgressUseCase progress) {
        this.pause = pause;
        this.resume = resume;
        this.progress = progress;
    }

    @EventListener
    public void on(TrainingSessionPauseChanged event) {
        if (event.paused()) {
            pause.pauseFromSession(event.userId(), event.sessionId(), event.at());
        } else {
            resume.resumeFromSession(event.userId(), event.sessionId(), event.at());
        }
    }

    @EventListener
    public void on(TrainingSessionProgressed event) {
        progress.sessionProgressed(event.userId(), event.sessionId());
    }

    @EventListener
    public void on(TrainingSessionCompletionChanged event) {
        progress.sessionProgressed(event.userId(), event.sessionId());
    }
}
