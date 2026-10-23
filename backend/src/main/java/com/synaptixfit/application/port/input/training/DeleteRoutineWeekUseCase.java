package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Borra una semana y renumera las siguientes. */
public interface DeleteRoutineWeekUseCase {

    Routine deleteWeek(UUID userId, UUID routineId, UUID weekId);
}
