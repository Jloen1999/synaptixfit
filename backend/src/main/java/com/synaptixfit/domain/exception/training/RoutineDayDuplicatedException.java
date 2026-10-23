package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** La semana ya tiene un día con ese número. */
public class RoutineDayDuplicatedException extends ConflictException {

    public RoutineDayDuplicatedException() {
        super("ROUTINE_DAY_DUPLICATED", "The week already has a day with that number");
    }
}
