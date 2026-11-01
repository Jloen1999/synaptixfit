package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Recupera un día saltado: vuelve a estar pendiente. */
public interface UnskipRoutineDayUseCase {

    Routine unskip(UUID userId, UUID routineId, UUID dayId);
}
