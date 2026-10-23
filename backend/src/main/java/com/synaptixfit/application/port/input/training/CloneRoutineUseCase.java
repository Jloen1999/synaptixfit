package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Clona en la cuenta propia una rutina visible de otro usuario, guardando su procedencia. */
public interface CloneRoutineUseCase {

    Routine cloneRoutine(UUID userId, UUID routineId);
}
