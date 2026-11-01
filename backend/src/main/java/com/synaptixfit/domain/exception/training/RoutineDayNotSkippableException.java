package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** Un día ya completado no se puede saltar (primero hay que desmarcar o eliminar su sesión). */
public class RoutineDayNotSkippableException extends ConflictException {

    public RoutineDayNotSkippableException(Object dayId) {
        super("ROUTINE_DAY_NOT_SKIPPABLE", "Routine day " + dayId + " is completed and cannot be skipped");
    }
}
