package com.synaptixfit.domain.exception.admin;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El inicio del rango de fechas no es anterior al final. */
public class AdminInvalidDateRangeException extends InvalidInputException {

    public AdminInvalidDateRangeException() {
        super("ADMIN_INVALID_DATE_RANGE", "'from' must be before 'to'");
    }
}
