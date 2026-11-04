package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** Se intenta apuntar un día del ciclo con el seguimiento desactivado. */
public class CycleTrackingOffException extends ConflictException {

    public CycleTrackingOffException() {
        super("CYCLE_TRACKING_OFF", "Cycle tracking is turned off");
    }
}
