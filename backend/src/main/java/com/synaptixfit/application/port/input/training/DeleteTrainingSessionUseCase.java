package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/**
 * Elimina una sesión. Si estaba sin terminar, la descarta con sus series; si estaba terminada, además
 * resta su XP y avisa para retirar su carga, su avance en retos y su bloque. El día vuelve a pendiente
 * si no tiene otra sesión terminada.
 */
public interface DeleteTrainingSessionUseCase {

    void delete(UUID userId, UUID sessionId);
}
