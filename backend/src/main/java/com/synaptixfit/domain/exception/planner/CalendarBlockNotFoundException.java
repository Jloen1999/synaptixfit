package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El bloque del calendario no existe o no es del usuario. */
public class CalendarBlockNotFoundException extends ResourceNotFoundException {

    public CalendarBlockNotFoundException(UUID id) {
        super("BLOCK_NOT_FOUND", "Calendar block", id);
    }
}
