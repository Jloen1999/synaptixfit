package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.RunWorkout;
import java.util.List;
import java.util.UUID;

/** Cambia el nombre y los pasos de un entreno de carrera del usuario. */
public interface UpdateRunWorkoutUseCase {

    record Command(UUID userId, UUID workoutId, String name, List<RunWorkout.Group> groups) {
    }

    RunWorkout updateWorkout(Command command);
}
