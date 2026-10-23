package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El día no existe en la rutina. */
public class RoutineDayNotFoundException extends ResourceNotFoundException {

    public RoutineDayNotFoundException(Object id) {
        super("ROUTINE_DAY_NOT_FOUND", "Routine day", id);
    }
}
