package com.synaptixfit.domain.model.social;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;

/** Filtro temporal del muro (como los chips del cliente: todo, hoy, esta semana, este mes). */
public enum FeedPeriod {
    ALL,
    TODAY,
    WEEK,
    MONTH;

    /** Instante desde el que se muestran publicaciones, o {@code null} para {@link #ALL}. */
    public Instant startFrom(Instant now, ZoneId zone) {
        LocalDate today = LocalDate.ofInstant(now, zone);
        LocalDate start = switch (this) {
            case ALL -> null;
            case TODAY -> today;
            case WEEK -> today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
            case MONTH -> today.withDayOfMonth(1);
        };
        return start == null ? null : start.atStartOfDay(zone).toInstant();
    }
}
