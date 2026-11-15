package com.synaptixfit.application.port.input.together;

import java.time.Instant;
import java.util.UUID;

/**
 * Pone en pausa a todo el grupo cuando una persona pausa su sesión de un entreno juntos (ADR 0047): pausa las sesiones
 * de los demás con el caso de uso de siempre (ADR 0030). Idempotente; si la sesión no es de entrenar juntos, nada.
 */
public interface PauseWorkoutTogetherUseCase {

    void pauseFromSession(UUID userId, UUID sessionId, Instant pausedAt);
}
