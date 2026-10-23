package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El plan semanal no existe o no es del usuario. */
public class StudyPlanNotFoundException extends ResourceNotFoundException {

    public StudyPlanNotFoundException(UUID id) {
        super("PLAN_NOT_FOUND", "Study plan", id);
    }
}
