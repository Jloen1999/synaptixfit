package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import java.util.UUID;

/** Activa, pausa, completa o archiva una rutina propia. */
public interface ChangeRoutineStatusUseCase {

    Routine changeStatus(UUID userId, UUID routineId, RoutineStatus status);
}
