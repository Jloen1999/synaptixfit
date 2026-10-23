package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Elimina (borrado lógico) una rutina propia. */
public interface DeleteRoutineUseCase {

    void delete(UUID userId, UUID routineId);
}
