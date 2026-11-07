package com.synaptixfit.domain.exception.run;

import com.synaptixfit.domain.exception.NotFoundException;

/** La carrera no existe o no es del usuario. */
public class RunNotFoundException extends NotFoundException {

    public RunNotFoundException(Object id) {
        super("RUN_NOT_FOUND", "Run not found: " + id);
    }
}
