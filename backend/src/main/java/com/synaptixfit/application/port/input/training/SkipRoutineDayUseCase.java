package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Salta un día de una rutina propia: deja de proponerse y el calendario retira sus bloques pendientes. */
public interface SkipRoutineDayUseCase {

    Routine skip(UUID userId, UUID routineId, UUID dayId);
}
