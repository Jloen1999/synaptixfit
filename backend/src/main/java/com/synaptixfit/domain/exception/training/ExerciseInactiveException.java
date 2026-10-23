package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** El ejercicio está desactivado y no se puede añadir a rutinas. */
public class ExerciseInactiveException extends BusinessRuleException {

    public ExerciseInactiveException() {
        super("EXERCISE_INACTIVE", "The exercise is not active");
    }
}
