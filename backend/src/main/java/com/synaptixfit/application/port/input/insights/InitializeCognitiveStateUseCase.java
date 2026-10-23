package com.synaptixfit.application.port.input.insights;

import java.util.UUID;

/** Crea el estado cognitivo inicial de un usuario nuevo. Idempotente. */
public interface InitializeCognitiveStateUseCase {

    void initializeCognitiveState(UUID userId);
}
