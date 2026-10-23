package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.WeekType;
import java.util.UUID;

/** Cambia el nombre o el tipo de una semana (los nulos no cambian). */
public interface UpdateRoutineWeekUseCase {

    Routine updateWeek(UUID userId, UUID routineId, UUID weekId, String name, WeekType type);
}
