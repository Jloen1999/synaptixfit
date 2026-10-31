package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.SessionHighlights;
import java.util.UUID;

/** Resumen destacado de una sesión propia terminada: volumen, récords y comparación con la anterior. */
public interface GetSessionHighlightsUseCase {

    /** Lanza SessionNotFoundException si la sesión no es del usuario o no está terminada. */
    SessionHighlights highlights(UUID userId, UUID sessionId);
}
