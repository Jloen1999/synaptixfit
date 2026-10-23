package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Duplica una rutina propia con el progreso a cero. */
public interface DuplicateRoutineUseCase {

    Routine duplicate(UUID userId, UUID routineId, String newName);
}
