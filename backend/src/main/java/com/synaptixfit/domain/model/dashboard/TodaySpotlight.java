package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.dashboard.Dashboard.TodayEvent;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Qué evento nombra la fila «ahora o a continuación» de «Tu día» (ADR 0059). A diferencia de
 * {@link TodaySummary#nextEventId()}, aquí sí entran las clases (la fila dice cuál, a qué hora y en qué aula), pero no
 * las entregas (tienen su propia fila, la cuenta atrás) ni los días de rutina (los nombra la fila del entreno).
 */
public final class TodaySpotlight {

    private TodaySpotlight() {
    }

    /**
     * Lo que está en curso; si no, lo próximo; si ya no queda nada por empezar, lo último que quedó sin hacer y aún se
     * puede marcar (una clase pasada no: nadie la marca). Nulo si no hay nada que nombrar.
     */
    public static UUID of(List<TodayEvent> events) {
        List<TodayEvent> candidates = events.stream().filter(TodaySpotlight::eligible).toList();
        Comparator<TodayEvent> byStart = Comparator.comparing(TodayEvent::start);
        return candidates.stream().filter(e -> e.status() == ItemTimeStatus.IN_PROGRESS).min(byStart)
                .or(() -> candidates.stream().filter(e -> e.status() == ItemTimeStatus.UPCOMING).min(byStart))
                .or(() -> candidates.stream()
                        .filter(e -> e.status() == ItemTimeStatus.MISSED && !e.completed()
                                && ActivityType.fromCode(e.type()) != ActivityType.CLASS)
                        .max(byStart))
                .map(TodayEvent::id)
                .orElse(null);
    }

    /** Bloques con seguimiento o clases, que no son el reflejo de un día de rutina. */
    static boolean eligible(TodayEvent e) {
        if (e.kind() != TodayEvent.Kind.BLOCK || e.routineDayId() != null) {
            return false;
        }
        ActivityType type = ActivityType.fromCode(e.type());
        return type.isTrackable() || type == ActivityType.CLASS;
    }
}
