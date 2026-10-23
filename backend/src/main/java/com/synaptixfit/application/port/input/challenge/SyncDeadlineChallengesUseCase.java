package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/**
 * Una entrega o examen ha cambiado de estado: completa o descompleta los retos y tareas
 * vinculados con su XP (regla de {@code sync_entrega_a_reto}). Idempotente.
 */
public interface SyncDeadlineChallengesUseCase {

    void syncDeadline(UUID userId, UUID deadlineId, boolean completed);
}
