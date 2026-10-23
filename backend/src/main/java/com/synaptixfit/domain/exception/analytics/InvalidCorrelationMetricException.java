package com.synaptixfit.domain.exception.analytics;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La métrica de entrenamiento para la correlación no es RPE ni MINUTES. */
public class InvalidCorrelationMetricException extends InvalidInputException {

    public InvalidCorrelationMetricException(String value) {
        super("ANALYTICS_INVALID_METRIC", "Invalid correlation metric: " + value);
    }
}
