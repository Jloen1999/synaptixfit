package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La rutina (o su semana/día) no existe o no es del usuario. */
public class PlannerRoutineNotFoundException extends ResourceNotFoundException {

    public PlannerRoutineNotFoundException(UUID id) {
        super("PLANNER_ROUTINE_NOT_FOUND", "Routine", id);
    }
}
