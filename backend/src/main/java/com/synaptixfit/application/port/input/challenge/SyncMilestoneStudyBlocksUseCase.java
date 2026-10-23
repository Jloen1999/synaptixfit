package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/**
 * Un bloque de estudio vinculado a una tarea ha cambiado: el progreso de la tarea pasa a ser el %
 * de sus bloques completados (regla de {@code fn_actualizar_progreso_hito}). Idempotente.
 */
public interface SyncMilestoneStudyBlocksUseCase {

    void syncStudyBlocks(UUID userId, UUID milestoneId);
}
