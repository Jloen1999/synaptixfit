package com.synaptixfit.domain.model.together;

import java.time.LocalDate;
import java.util.Set;

/**
 * Días de una racha con un amigo (ADR 0044). Un día suma si los dos hicieron algo que cuenta. Si alguno de los dos
 * tenía la racha en pausa ese día (ADR 0042) y no lo hicieron los dos, el día ni suma ni rompe: la pausa de uno
 * protege la racha compartida. Cualquier otro día pasado sin hacer la rompe (vuelve a 0). Hoy suma en cuanto los dos
 * lo hacen y no rompe hasta que termina. No cuenta nada antes del día en que se aceptó.
 */
public final class FriendStreakCount {

    private FriendStreakCount() {
    }

    public static int days(LocalDate since, LocalDate today, Set<LocalDate> doneA, Set<LocalDate> doneB,
                           Set<LocalDate> pausedA, Set<LocalDate> pausedB) {
        if (since == null || since.isAfter(today)) {
            return 0;
        }
        int days = doneA.contains(today) && doneB.contains(today) ? 1 : 0;
        for (LocalDate d = today.minusDays(1); !d.isBefore(since); d = d.minusDays(1)) {
            if (doneA.contains(d) && doneB.contains(d)) {
                days++;
            } else if (!pausedA.contains(d) && !pausedB.contains(d)) {
                break;
            }
        }
        return days;
    }
}
