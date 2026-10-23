package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/**
 * Recalcula desde cero las sesiones de entrenamiento de los retos de fitness con objetivo de
 * sesiones del usuario, completándolos o descompletándolos con su XP (ADR 0009). Idempotente: lo
 * invoca el oyente de {@code TrainingSessionCompletionChanged}.
 */
public interface SyncTrainingSessionChallengesUseCase {

    void syncTrainingSessions(UUID userId);
}
