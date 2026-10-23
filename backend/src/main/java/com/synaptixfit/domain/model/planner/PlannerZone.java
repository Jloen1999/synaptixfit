package com.synaptixfit.domain.model.planner;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.Objects;

/**
 * Zona horaria de referencia del planificador: define qué es «un día» y «una semana» (de lunes a
 * domingo) y convierte horas de reloj (09:00 de un lunes) en instantes.
 */
public record PlannerZone(ZoneId zone) {

    public PlannerZone {
        Objects.requireNonNull(zone, "zone");
    }

    public static PlannerZone of(String zoneId) {
        return new PlannerZone(ZoneId.of(zoneId));
    }

    /** Lunes de la semana que contiene {@code date}. */
    public static LocalDate mondayOf(LocalDate date) {
        return date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    public LocalDate today(Instant now) {
        return localDate(now);
    }

    public LocalDate localDate(Instant instant) {
        return instant.atZone(zone).toLocalDate();
    }

    public LocalTime localTime(Instant instant) {
        return instant.atZone(zone).toLocalTime();
    }

    public int dayOfWeek(Instant instant) {
        return instant.atZone(zone).getDayOfWeek().getValue();
    }

    public Instant at(LocalDate date, LocalTime time) {
        return date.atTime(time).atZone(zone).toInstant();
    }

    public Instant startOfDay(LocalDate date) {
        return date.atStartOfDay(zone).toInstant();
    }

    /**
     * El mismo instante {@code weeks} semanas después, a la misma hora local (con cambio de hora
     * entre medias, la hora del reloj se mantiene).
     */
    public Instant plusWeeks(Instant instant, int weeks) {
        return instant.atZone(zone).plusWeeks(weeks).toInstant();
    }

    /** Inicio de la semana (lunes 00:00) que contiene {@code date}. */
    public Instant weekStart(LocalDate date) {
        return startOfDay(mondayOf(date));
    }

    /** Fin exclusivo de la semana (lunes siguiente 00:00) que contiene {@code date}. */
    public Instant weekEnd(LocalDate date) {
        return startOfDay(mondayOf(date).plusDays(7));
    }
}
