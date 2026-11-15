package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Empieza (o retoma) la sesión normal de la persona para entrenar juntos y devuelve su id. */
public interface StartWorkoutTogetherUseCase {

    UUID start(UUID userId, UUID workoutId);
}
