package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La rutina no existe, está eliminada o no es visible para el usuario. */
public class RoutineNotFoundException extends ResourceNotFoundException {

    public RoutineNotFoundException(Object id) {
        super("ROUTINE_NOT_FOUND", "Routine", id);
    }
}
