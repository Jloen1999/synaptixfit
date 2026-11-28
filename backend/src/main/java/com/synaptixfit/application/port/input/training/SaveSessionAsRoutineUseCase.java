package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** «Guardar como rutina»: crea una rutina propia de un día con lo hecho en una sesión libre (ADR 0067). */
public interface SaveSessionAsRoutineUseCase {

    Routine saveAsRoutine(UUID userId, UUID sessionId, String name);
}
