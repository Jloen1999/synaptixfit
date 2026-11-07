package com.synaptixfit.domain.exception.run;

import com.synaptixfit.domain.exception.NotFoundException;

/** El entreno de carrera (o la plantilla) no existe o no es del usuario. */
public class RunWorkoutNotFoundException extends NotFoundException {

    public RunWorkoutNotFoundException(Object id) {
        super("RUN_WORKOUT_NOT_FOUND", "Run workout not found: " + id);
    }
}
