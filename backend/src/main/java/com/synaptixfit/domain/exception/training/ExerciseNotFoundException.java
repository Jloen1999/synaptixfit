package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El ejercicio no existe (o está inactivo para usuarios). */
public class ExerciseNotFoundException extends ResourceNotFoundException {

    public ExerciseNotFoundException(Object id) {
        super("EXERCISE_NOT_FOUND", "Exercise", id);
    }
}
