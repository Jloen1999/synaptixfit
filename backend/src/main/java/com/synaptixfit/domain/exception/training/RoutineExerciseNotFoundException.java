package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El ejercicio planificado no existe en la rutina. */
public class RoutineExerciseNotFoundException extends ResourceNotFoundException {

    public RoutineExerciseNotFoundException(Object id) {
        super("ROUTINE_EXERCISE_NOT_FOUND", "Routine exercise", id);
    }
}
