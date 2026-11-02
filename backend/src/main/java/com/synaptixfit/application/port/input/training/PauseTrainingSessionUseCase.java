package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Pausa una sesión en curso: el tiempo deja de contar como entrenamiento hasta reanudarla (ADR 0030). */
public interface PauseTrainingSessionUseCase {

    TrainingSession pause(UUID userId, UUID sessionId);
}
