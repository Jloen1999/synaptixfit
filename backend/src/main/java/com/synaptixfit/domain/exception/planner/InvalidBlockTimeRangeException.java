package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Rango horario inválido: el fin debe ser posterior al inicio y durar al menos 30 minutos. */
public class InvalidBlockTimeRangeException extends InvalidInputException {

    public InvalidBlockTimeRangeException() {
        super("BLOCK_INVALID_TIME_RANGE", "The block must end after it starts and last at least 30 minutes");
    }
}
