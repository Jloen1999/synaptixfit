package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/**
 * Una entrega o examen ha cambiado de estado: completa o descompleta las tareas vinculadas (y el reto sin
 * tareas vinculado) con su XP. La entrega es la fuente de verdad; el camino inverso no existe (ADR 0028).
 * Idempotente.
 */
public interface SyncDeadlineChallengesUseCase {

    void syncDeadline(UUID userId, UUID deadlineId, boolean completed);
}
