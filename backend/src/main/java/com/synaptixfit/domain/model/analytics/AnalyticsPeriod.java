package com.synaptixfit.domain.model.analytics;

import com.synaptixfit.domain.exception.analytics.InvalidAnalyticsPeriodException;
import java.util.Locale;

/** Ventana de la analítica: 4 (semanal), 12 (mensual) o 26 semanas (trimestral). Por defecto MONTHLY. */
public enum AnalyticsPeriod {
    WEEKLY(4),
    MONTHLY(12),
    QUARTERLY(26);

    private final int weeks;

    AnalyticsPeriod(int weeks) {
        this.weeks = weeks;
    }

    public int weeks() {
        return weeks;
    }

    public static AnalyticsPeriod parse(String value) {
        if (value == null || value.isBlank()) {
            return MONTHLY;
        }
        try {
            return valueOf(value.strip().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new InvalidAnalyticsPeriodException(value);
        }
    }
}
