package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Dice que no a entrenar juntos hoy. */
public interface DeclineWorkoutTogetherUseCase {

    void decline(UUID userId, UUID workoutId);
}
