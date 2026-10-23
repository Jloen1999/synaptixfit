package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Aplica a una entrega el estado de un reto o tarea de reto vinculados (oyente de
 * {@code ChallengeLinkCompletionChanged}). Solo actúa si el estado cambia; en ese caso aplica la
 * experiencia y publica {@code DeadlineCompletionChanged} como un cambio manual. Ignora entregas
 * inexistentes o de otro usuario.
 */
public interface SyncDeadlineFromChallengeUseCase {

    void syncFromChallenge(UUID userId, UUID deadlineId, boolean completed);
}
