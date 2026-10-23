package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.exception.insights.InvalidTimeZoneException;
import java.time.DateTimeException;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;

/**
 * Utilidades de calendario. "Hoy" y "esta semana" dependen de la zona del usuario: el servidor
 * trabaja en UTC y el cliente indica su zona IANA (si no, se usa la zona por defecto configurada).
 */
public final class TimeZones {

    private TimeZones() {
    }

    public static ZoneId resolve(String zone, ZoneId fallback) {
        if (zone == null || zone.isBlank()) {
            return fallback;
        }
        try {
            return ZoneId.of(zone.strip());
        } catch (DateTimeException e) {
            throw new InvalidTimeZoneException(zone);
        }
    }

    public static Instant startOfDay(LocalDate day, ZoneId zone) {
        return day.atStartOfDay(zone).toInstant();
    }

    /** Lunes de la semana (ISO) que contiene {@code day}. */
    public static LocalDate weekStart(LocalDate day) {
        return day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }
}
