package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.NotFoundException;
import java.util.UUID;

/** El «Entrenamos juntos» no existe o la persona no está invitada. */
public class WorkoutTogetherNotFoundException extends NotFoundException {

    public WorkoutTogetherNotFoundException(UUID id) {
        super("WORKOUT_TOGETHER_NOT_FOUND", "Workout together " + id + " not found");
    }
}
