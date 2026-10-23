package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El rango de fechas pedido es inválido o demasiado grande. */
public class PlannerRangeTooLargeException extends InvalidInputException {

    public PlannerRangeTooLargeException() {
        super("PLANNER_RANGE_TOO_LARGE", "The requested date range is invalid or too large (max 92 days)");
    }
}
