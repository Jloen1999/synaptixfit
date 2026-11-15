package com.synaptixfit.application.port.input.together;

import java.util.Optional;
import java.util.UUID;

/** El «Entrenamos juntos» de una sesión propia, si lo hay (para la sesión en vivo y su resumen). */
public interface FindWorkoutTogetherBySessionUseCase {

    Optional<WorkoutTogetherView> bySession(UUID userId, UUID sessionId);
}
