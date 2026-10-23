package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ConflictException;
import java.util.UUID;

/** La tarea ya está completada. */
public class MilestoneAlreadyCompletedException extends ConflictException {

    public MilestoneAlreadyCompletedException(UUID id) {
        super("MILESTONE_ALREADY_COMPLETED", "milestone " + id + " is already completed");
    }
}
