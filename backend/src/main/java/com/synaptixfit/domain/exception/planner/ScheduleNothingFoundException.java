package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La IA no ha encontrado ninguna de tus asignaturas en el documento. */
public class ScheduleNothingFoundException extends BusinessRuleException {

    public ScheduleNothingFoundException() {
        super("SCHEDULE_NOTHING_FOUND", "None of your subjects was found in the document");
    }
}
