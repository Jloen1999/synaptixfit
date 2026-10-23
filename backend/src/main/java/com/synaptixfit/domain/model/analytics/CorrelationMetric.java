package com.synaptixfit.domain.model.analytics;

import com.synaptixfit.domain.exception.analytics.InvalidCorrelationMetricException;
import java.util.Locale;

/** Variable de entrenamiento que se correlaciona con las horas de estudio semanales. Por defecto RPE. */
public enum CorrelationMetric {
    /** RPE medio semanal. */
    RPE,
    /** Minutos de entrenamiento semanales. */
    MINUTES;

    public static CorrelationMetric parse(String value) {
        if (value == null || value.isBlank()) {
            return RPE;
        }
        try {
            return valueOf(value.strip().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new InvalidCorrelationMetricException(value);
        }
    }
}
