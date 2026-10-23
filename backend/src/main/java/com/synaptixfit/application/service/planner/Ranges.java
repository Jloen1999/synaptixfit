package com.synaptixfit.application.service.planner;

import com.synaptixfit.domain.exception.planner.PlannerRangeTooLargeException;
import java.time.Duration;
import java.time.Instant;

/** Límites de los rangos de consulta (evitan volcados masivos). */
final class Ranges {

    /** Rango máximo de bloques, línea de tiempo… */
    static final int MAX_QUERY_DAYS = 92;
    /** Rango máximo de la exportación ICS. */
    static final int MAX_EXPORT_DAYS = 400;

    private Ranges() {
    }

    static void check(Instant from, Instant to, int maxDays) {
        if (from == null || to == null || !to.isAfter(from) || Duration.between(from, to).toDays() > maxDays) {
            throw new PlannerRangeTooLargeException();
        }
    }
}
