package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/**
 * Avisa en directo al grupo de que una persona apuntó una serie o terminó su sesión (ADR 0047), para que su panel de
 * «quién lleva cada ejercicio» se actualice al momento. No cambia nada; si la sesión no es de entrenar juntos, nada.
 */
public interface NotifyWorkoutTogetherProgressUseCase {

    void sessionProgressed(UUID userId, UUID sessionId);
}
