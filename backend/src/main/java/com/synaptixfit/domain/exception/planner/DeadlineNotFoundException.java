package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La entrega o examen no existe o no es del usuario. */
public class DeadlineNotFoundException extends ResourceNotFoundException {

    public DeadlineNotFoundException(UUID id) {
        super("DEADLINE_NOT_FOUND", "Deadline", id);
    }
}
