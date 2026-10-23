package com.synaptixfit.application.port.input.insights;

import java.util.UUID;

/**
 * Recalcula el estado cognitivo de hoy tras completar o desmarcar un bloque o terminar una práctica
 * (Pomodoro, test, repaso). Los bloques sin coste cognitivo (deporte, comida…) se ignoran.
 * Idempotente: el estado se recalcula desde cero.
 */
public interface RefreshCognitiveStateUseCase {

    /** @param activityType código del bloque; null si la causa es una práctica (siempre cognitiva) */
    record Command(UUID userId, String activityType) {}

    void refreshCognitiveState(Command command);
}
