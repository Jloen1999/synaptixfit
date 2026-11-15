package com.synaptixfit.application.port.input.together;

import java.util.Set;
import java.util.UUID;

/** Invita a amigos mutuos a hacer hoy un día de la rutina propia; sin día, el siguiente por hacer. */
public interface CreateWorkoutTogetherUseCase {

    WorkoutTogetherView create(Command command);

    record Command(UUID userId, UUID routineId, UUID dayId, Set<UUID> friendIds) {
    }
}
