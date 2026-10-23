package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Detalle de una sesión propia con sus series. */
public interface GetTrainingSessionUseCase {

    TrainingSession get(UUID userId, UUID sessionId);
}
