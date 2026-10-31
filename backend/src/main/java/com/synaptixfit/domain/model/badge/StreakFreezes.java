package com.synaptixfit.domain.model.badge;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Comodines de racha (ADR 0023): un día sin actividad no rompe la racha si hay un comodín. Se gana uno por cada
 * {@link #DAYS_PER_FREEZE} días seguidos con actividad y se guardan como mucho {@link #MAX_FREEZES}; el día salvado
 * no suma a la racha, pero tampoco la corta. Se calcula entero desde el historial de días activos (no se guarda
 * nada): el resultado es el mismo en cada consulta.
 *
 * <p>Por qué: una racha que se pierde por un solo día (un examen, un viaje) desanima más de lo que motiva; con
 * comodines limitados la constancia sigue contando.
 */
public final class StreakFreezes {

    public static final int DAYS_PER_FREEZE = 7;
    public static final int MAX_FREEZES = 2;

    /**
     * @param currentDays días con actividad de la racha actual (los salvados no cuentan)
     * @param available   comodines que quedan para los próximos días sin actividad
     * @param frozenDays  días de la racha actual salvados con un comodín
     */
    public record Run(int currentDays, int available, List<LocalDate> frozenDays) {
    }

    private StreakFreezes() {
    }

    /** Recorre el historial de días activos hasta hoy. Hoy, aún sin actividad, no rompe ni gasta comodín. */
    public static Run run(Set<LocalDate> activeDays, LocalDate today) {
        if (activeDays.isEmpty()) {
            return new Run(0, 0, List.of());
        }
        LocalDate first = activeDays.stream().min(LocalDate::compareTo).orElseThrow();
        int current = 0;
        int sinceFreeze = 0;
        int available = 0;
        List<LocalDate> frozen = new ArrayList<>();
        for (LocalDate day = first; day.isBefore(today); day = day.plusDays(1)) {
            if (activeDays.contains(day)) {
                current++;
                sinceFreeze++;
                if (sinceFreeze == DAYS_PER_FREEZE) {
                    available = Math.min(MAX_FREEZES, available + 1);
                    sinceFreeze = 0;
                }
            } else if (current > 0 && available > 0) {
                available--;
                frozen.add(day);
            } else {
                current = 0;
                sinceFreeze = 0;
                available = 0;
                frozen.clear();
            }
        }
        if (activeDays.contains(today)) {
            current++;
            sinceFreeze++;
            if (sinceFreeze == DAYS_PER_FREEZE) {
                available = Math.min(MAX_FREEZES, available + 1);
            }
        }
        return new Run(current, available, List.copyOf(frozen));
    }
}
