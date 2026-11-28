package com.synaptixfit.domain.exception.wod;

import com.synaptixfit.domain.exception.NotFoundException;

/** El WOD no existe o no es del usuario. */
public class WodNotFoundException extends NotFoundException {

    public WodNotFoundException(Object id) {
        super("WOD_NOT_FOUND", "WOD not found: " + id);
    }
}
