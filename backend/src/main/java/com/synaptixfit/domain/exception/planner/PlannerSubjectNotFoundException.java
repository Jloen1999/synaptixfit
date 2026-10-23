package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La asignatura no existe o no es del usuario. */
public class PlannerSubjectNotFoundException extends ResourceNotFoundException {

    public PlannerSubjectNotFoundException(UUID id) {
        super("PLANNER_SUBJECT_NOT_FOUND", "Subject", id);
    }
}
