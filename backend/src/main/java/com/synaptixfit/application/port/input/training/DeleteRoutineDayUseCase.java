package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Borra un día y sus ejercicios. */
public interface DeleteRoutineDayUseCase {

    Routine deleteDay(UUID userId, UUID routineId, UUID dayId);
}
