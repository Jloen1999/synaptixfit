package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La plantilla de rutina no existe. */
public class RoutineTemplateNotFoundException extends ResourceNotFoundException {

    public RoutineTemplateNotFoundException(Object id) {
        super("ROUTINE_TEMPLATE_NOT_FOUND", "Routine template", id);
    }
}
