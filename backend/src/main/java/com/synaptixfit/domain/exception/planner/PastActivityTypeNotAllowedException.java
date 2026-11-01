package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Solo se apuntan a posteriori deporte y estudio (no clases, exámenes, entregas, descanso, comida ni sueño). */
public class PastActivityTypeNotAllowedException extends BusinessRuleException {

    public PastActivityTypeNotAllowedException() {
        super("PLANNER_PAST_ACTIVITY_TYPE_NOT_ALLOWED", "Only sport and study can be logged after the fact");
    }
}
