package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ExternalServiceException;

/** No se ha podido descargar o interpretar el calendario ICS. */
public class IcsFeedUnavailableException extends ExternalServiceException {

    public IcsFeedUnavailableException() {
        super("PLANNER_ICS_UNAVAILABLE", "The ICS calendar could not be downloaded or parsed");
    }
}
