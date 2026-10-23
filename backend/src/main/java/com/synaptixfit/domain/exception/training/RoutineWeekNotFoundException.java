package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La semana no existe en la rutina. */
public class RoutineWeekNotFoundException extends ResourceNotFoundException {

    public RoutineWeekNotFoundException(Object id) {
        super("ROUTINE_WEEK_NOT_FOUND", "Routine week", id);
    }
}
