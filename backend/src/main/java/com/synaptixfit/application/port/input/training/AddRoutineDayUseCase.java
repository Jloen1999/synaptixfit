package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Añade un día (1-7) a una semana. */
public interface AddRoutineDayUseCase {

    Routine addDay(UUID userId, UUID routineId, UUID weekId, int dayNumber, String name);
}
