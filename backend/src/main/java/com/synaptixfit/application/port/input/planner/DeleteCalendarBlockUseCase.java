package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Borra un bloque. Si estaba completado y había dado experiencia, se resta (evita ganar experiencia
 * creando, completando y borrando bloques).
 */
public interface DeleteCalendarBlockUseCase {

    void deleteBlock(UUID userId, UUID blockId);
}
