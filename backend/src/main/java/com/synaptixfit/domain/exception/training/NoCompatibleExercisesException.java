package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No hay ejercicios compatibles con el equipamiento y el nivel del usuario. */
public class NoCompatibleExercisesException extends BusinessRuleException {

    public NoCompatibleExercisesException() {
        super("TRAINING_NO_COMPATIBLE_EXERCISES", "No exercises match the user's equipment and level");
    }
}
