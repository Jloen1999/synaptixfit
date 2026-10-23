package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Cambia el nombre de un día. */
public interface RenameRoutineDayUseCase {

    Routine renameDay(UUID userId, UUID routineId, UUID dayId, String name);
}
