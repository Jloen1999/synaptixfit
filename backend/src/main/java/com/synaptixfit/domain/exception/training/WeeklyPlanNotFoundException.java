package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** No hay plan semanal para esa semana. */
public class WeeklyPlanNotFoundException extends ResourceNotFoundException {

    public WeeklyPlanNotFoundException(Object id) {
        super("TRAINING_PLAN_NOT_FOUND", "Weekly training plan", id);
    }
}
