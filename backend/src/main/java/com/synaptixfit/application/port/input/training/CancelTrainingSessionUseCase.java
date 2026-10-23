package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Abandona (borra) una sesión en curso. */
public interface CancelTrainingSessionUseCase {

    void cancel(UUID userId, UUID sessionId);
}
