package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.InvalidInputException;
import java.time.LocalDate;

/** La fecha de fin de clases es anterior a la de inicio. */
public class InvalidClassDatesException extends InvalidInputException {

    public InvalidClassDatesException(LocalDate start, LocalDate end) {
        super("PROFILE_INVALID_CLASS_DATES", "Classes end date " + end + " is before start date " + start);
    }
}
