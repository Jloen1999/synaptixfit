package com.synaptixfit.application.port.input.run;

import java.util.UUID;

/**
 * Borra un entreno de carrera. Los eventos que ya estaban en el calendario se quedan (como Entreno normal) y las
 * carreras grabadas con él no cambian.
 */
public interface DeleteRunWorkoutUseCase {

    void deleteWorkout(UUID userId, UUID workoutId);
}
