package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Acepta la invitación a entrenar juntos hoy. */
public interface JoinWorkoutTogetherUseCase {

    WorkoutTogetherView join(UUID userId, UUID workoutId);
}
