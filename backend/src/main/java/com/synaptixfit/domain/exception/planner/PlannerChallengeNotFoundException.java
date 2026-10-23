package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El reto o la tarea de reto vinculados no existen o no son del usuario. */
public class PlannerChallengeNotFoundException extends ResourceNotFoundException {

    public PlannerChallengeNotFoundException(UUID id) {
        super("PLANNER_CHALLENGE_NOT_FOUND", "Challenge", id);
    }
}
