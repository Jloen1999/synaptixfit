package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No hay URL ICS: ni en la petición ni en la asignatura. */
public class IcsUrlMissingException extends BusinessRuleException {

    public IcsUrlMissingException() {
        super("PLANNER_ICS_URL_MISSING", "The subject has no ICS URL configured");
    }
}
