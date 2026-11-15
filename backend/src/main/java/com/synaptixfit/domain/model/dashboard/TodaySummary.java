package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.dashboard.Dashboard.TodayEvent;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Resumen de «Tu día» (ADR 0050), calculado sobre los eventos de hoy de {@link Dashboard}: el anillo
 * ({@code done}/{@code total}), lo que quedó sin hacer ({@code missed}), qué evento destacar ({@code nextEventId}) y en
 * qué punto está el día ({@link State}). Así Inicio dice lo mismo que la agenda: nunca «Has terminado» con algo sin hacer.
 */
public record TodaySummary(int done, int total, int missed, UUID nextEventId, State state) {

    private static final TodaySummary NOTHING = new TodaySummary(0, 0, 0, null, State.NOTHING_PLANNED);

    /** En qué punto está el día. */
    public enum State {
        /** Nada de hoy que cuente (como mucho clases, comidas o descansos). */
        NOTHING_PLANNED,
        /** Queda algo en curso o por empezar. */
        PENDING,
        /** Lo que queda ya pasó sin hacerse: aún se puede marcar. */
        MISSED_LEFT,
        /** Todo lo que cuenta está hecho (y hay al menos uno). */
        ALL_DONE
    }

    /**
     * Cuentan los eventos con seguimiento salvo las clases (nadie las marca y el anillo se quedaba a medias aunque
     * fueras a todas) y las entregas de hoy, que también se marcan. Hecho = completado; pendiente = el resto, esté por
     * empezar, en curso o sin hacer. Lo que se destaca: lo que está en curso; si no, lo próximo; si ya no queda nada
     * por empezar, lo último que quedó sin hacer (lo más reciente es lo más fácil de recuperar).
     */
    public static TodaySummary of(List<TodayEvent> events) {
        List<TodayEvent> counted = events.stream().filter(TodaySummary::counts).toList();
        if (counted.isEmpty()) {
            return NOTHING;
        }
        List<TodayEvent> pending = counted.stream().filter(e -> !e.completed()).toList();
        int done = counted.size() - pending.size();
        int missed = (int) pending.stream().filter(e -> e.status() == ItemTimeStatus.MISSED).count();
        if (pending.isEmpty()) {
            return new TodaySummary(done, counted.size(), 0, null, State.ALL_DONE);
        }
        Comparator<TodayEvent> byStart = Comparator.comparing(TodayEvent::start);
        TodayEvent active = pending.stream().filter(e -> e.status() == ItemTimeStatus.IN_PROGRESS).min(byStart)
                .or(() -> pending.stream().filter(e -> e.status() == ItemTimeStatus.UPCOMING).min(byStart))
                .orElse(null);
        if (active != null) {
            return new TodaySummary(done, counted.size(), missed, active.id(), State.PENDING);
        }
        TodayEvent latestMissed = pending.stream().max(byStart).orElseThrow();
        return new TodaySummary(done, counted.size(), missed, latestMissed.id(), State.MISSED_LEFT);
    }

    /** ¿Cuenta en «Tu día»? Las entregas de hoy, sí; de los bloques, los que tienen seguimiento menos las clases. */
    static boolean counts(TodayEvent e) {
        if (e.kind() == TodayEvent.Kind.DEADLINE) {
            return true;
        }
        ActivityType type = ActivityType.fromCode(e.type());
        return type.isTrackable() && type != ActivityType.CLASS;
    }
}
