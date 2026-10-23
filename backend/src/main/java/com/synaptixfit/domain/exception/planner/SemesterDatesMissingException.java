package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Faltan las fechas de inicio y fin de clases en el perfil académico. */
public class SemesterDatesMissingException extends BusinessRuleException {

    public SemesterDatesMissingException() {
        super("SCHEDULE_SEMESTER_DATES_MISSING", "The academic profile has no semester start/end dates");
    }
}
