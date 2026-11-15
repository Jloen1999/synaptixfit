package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/**
 * «Empezar» de un entreno juntos (ADR 0047): lo puede pulsar cualquiera de dentro (o invitado, que entra al pulsarlo).
 * La primera vez empieza para todo el grupo: crea, en la misma transacción, la sesión normal de cada persona de dentro
 * con la misma hora de inicio. Después solo retoma (o crea, si le faltaba) la sesión de quien lo pulsa. Devuelve la
 * sesión de quien lo pulsa.
 */
public interface StartWorkoutTogetherUseCase {

    UUID start(UUID userId, UUID workoutId);
}
