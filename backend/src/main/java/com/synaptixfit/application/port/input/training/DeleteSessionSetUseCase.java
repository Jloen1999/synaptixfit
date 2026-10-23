package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Borra una serie de una sesión en curso. */
public interface DeleteSessionSetUseCase {

    TrainingSession deleteSet(UUID userId, UUID sessionId, UUID setId);
}
