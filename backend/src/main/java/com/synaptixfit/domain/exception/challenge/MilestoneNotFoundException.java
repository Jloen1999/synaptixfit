package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La tarea no existe en el reto indicado. */
public class MilestoneNotFoundException extends ResourceNotFoundException {

    public MilestoneNotFoundException(UUID id) {
        super("MILESTONE_NOT_FOUND", "Milestone", id);
    }
}
