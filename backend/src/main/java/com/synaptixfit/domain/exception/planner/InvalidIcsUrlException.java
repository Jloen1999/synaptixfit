package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La URL del calendario ICS no es válida. */
public class InvalidIcsUrlException extends InvalidInputException {

    public InvalidIcsUrlException() {
        super("PLANNER_ICS_URL_INVALID", "The ICS URL must be an http(s) or webcal URL");
    }
}
