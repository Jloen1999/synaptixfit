package com.synaptixfit.domain.exception.analytics;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El periodo de analítica no es WEEKLY, MONTHLY ni QUARTERLY. */
public class InvalidAnalyticsPeriodException extends InvalidInputException {

    public InvalidAnalyticsPeriodException(String value) {
        super("ANALYTICS_INVALID_PERIOD", "Invalid analytics period: " + value);
    }
}
