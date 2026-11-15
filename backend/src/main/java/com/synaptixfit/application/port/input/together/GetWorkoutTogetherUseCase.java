package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Detalle de un «Entrenamos juntos» con quién tiene hecho cada ejercicio. */
public interface GetWorkoutTogetherUseCase {

    WorkoutTogetherView get(UUID userId, UUID workoutId);
}
