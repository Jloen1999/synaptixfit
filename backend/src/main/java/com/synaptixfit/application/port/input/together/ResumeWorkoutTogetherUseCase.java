package com.synaptixfit.application.port.input.together;

import java.time.Instant;
import java.util.UUID;

/**
 * Reanuda a todo el grupo cuando una persona reanuda su sesión de un entreno juntos (ADR 0047), con la misma hora de
 * reanudación para todos. Idempotente; si la sesión no es de entrenar juntos, nada.
 */
public interface ResumeWorkoutTogetherUseCase {

    void resumeFromSession(UUID userId, UUID sessionId, Instant resumedAt);
}
