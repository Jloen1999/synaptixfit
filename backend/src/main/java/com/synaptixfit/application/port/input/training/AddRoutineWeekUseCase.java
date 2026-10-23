package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.WeekType;
import java.util.UUID;

/** Añade una semana al final de una rutina propia. */
public interface AddRoutineWeekUseCase {

    Routine addWeek(UUID userId, UUID routineId, String name, WeekType type);
}
