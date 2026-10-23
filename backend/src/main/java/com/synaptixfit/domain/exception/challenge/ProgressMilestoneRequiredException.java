package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** En un reto con tareas el progreso se registra en una tarea concreta. */
public class ProgressMilestoneRequiredException extends BusinessRuleException {

    public ProgressMilestoneRequiredException() {
        super("CHALLENGE_PROGRESS_MILESTONE_REQUIRED", "a challenge with milestones records progress per milestone");
    }
}
