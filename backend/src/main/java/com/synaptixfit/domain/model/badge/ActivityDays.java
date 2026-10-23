package com.synaptixfit.domain.model.badge;

import java.time.LocalDate;
import java.util.Set;
import java.util.TreeSet;

/** Cálculo de días consecutivos con actividad. */
public final class ActivityDays {

    private ActivityDays() {
    }

    /**
     * Días consecutivos con actividad que terminan hoy o, si hoy aún no hay actividad, ayer (la
     * racha sigue viva hasta que acaba el día). Corrige el cálculo antiguo, que devolvía 0 cuando la
     * última actividad era de ayer.
     */
    public static int currentRun(Set<LocalDate> days, LocalDate today) {
        LocalDate cursor = days.contains(today) ? today : today.minusDays(1);
        int run = 0;
        while (days.contains(cursor)) {
            run++;
            cursor = cursor.minusDays(1);
        }
        return run;
    }

    /** Racha más larga de la historia. */
    public static int longestRun(Set<LocalDate> days) {
        int best = 0;
        int run = 0;
        LocalDate previous = null;
        for (LocalDate day : new TreeSet<>(days)) {
            run = previous != null && previous.plusDays(1).equals(day) ? run + 1 : 1;
            best = Math.max(best, run);
            previous = day;
        }
        return best;
    }
}
