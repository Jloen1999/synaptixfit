package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.VisibleRoutine;
import java.util.UUID;

/** Detalle de una rutina propia o visible para el usuario (pública o de un amigo). */
public interface GetRoutineUseCase {

    VisibleRoutine get(UUID userId, UUID routineId);
}
