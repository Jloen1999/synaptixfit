package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.time.Instant;
import java.util.UUID;

/** Reanuda una sesión en pausa; el tiempo en pausa queda descontado de la duración (ADR 0030). */
public interface ResumeTrainingSessionUseCase {

    /**
     * @param resumedAt cuándo se reanudó en el móvil (puede llegar tarde si no había conexión); nulo es
     *                  «ahora».
     */
    TrainingSession resume(UUID userId, UUID sessionId, Instant resumedAt);
}
