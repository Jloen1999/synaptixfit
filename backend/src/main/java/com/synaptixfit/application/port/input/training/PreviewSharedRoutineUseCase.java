package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/**
 * Quien abre un enlace (con sesión) ve la rutina antes de copiarla (ADR 0043). Solo la rutina: nada del dueño.
 */
public interface PreviewSharedRoutineUseCase {

    Routine previewSharedRoutine(UUID userId, String token);
}
