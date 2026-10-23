package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import java.util.UUID;

/** Rutinas del usuario (no eliminadas), opcionalmente filtradas por estado. */
public interface ListMyRoutinesUseCase {

    PageResult<Routine> listMine(UUID userId, RoutineStatus status, PageRequest page);
}
