package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La reordenación debe incluir exactamente los ejercicios del día. */
public class RoutineReorderMismatchException extends InvalidInputException {

    public RoutineReorderMismatchException() {
        super("ROUTINE_REORDER_MISMATCH", "The new order must contain exactly the exercises of the day");
    }
}
