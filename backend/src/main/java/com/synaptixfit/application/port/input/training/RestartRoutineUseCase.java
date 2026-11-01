package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** Empieza un ciclo nuevo de una rutina propia (avance a cero, desde hoy y en curso). */
public interface RestartRoutineUseCase {

    Routine restart(UUID userId, UUID routineId);
}
