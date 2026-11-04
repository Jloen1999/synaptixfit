package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/**
 * Algo vinculado a un reto ha cambiado de estado (una entrega, un examen o un día de rutina): completa o
 * descompleta las tareas vinculadas a ese id (y el reto sin tareas vinculado) con su XP. La entidad vinculada
 * es la fuente de verdad; el camino inverso no existe (ADR 0028 y 0032). Idempotente.
 */
public interface SyncLinkedEntityChallengesUseCase {

    void syncLinkedEntity(UUID userId, UUID entityId, boolean completed);
}
