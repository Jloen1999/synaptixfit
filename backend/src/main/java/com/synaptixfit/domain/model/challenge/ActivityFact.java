package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/**
 * Una cosa hecha que puede contar en un reto automático (ADR 0043). {@code at} es cuándo se hizo (decide si cae dentro
 * del reto); {@code day} es el día al que pertenece si el otro módulo lo guarda como fecha (el registro diario, el
 * lunes de la semana planificada). Al menos uno de los dos. {@code amount}: minutos de un Pomodoro; 1 en el resto.
 */
public record ActivityFact(ActivityKind kind, Instant at, LocalDate day, int amount) {

    public ActivityFact {
        Guard.notNull(kind, "kind");
        if (at == null) {
            Guard.notNull(day, "day");
        }
        amount = Math.max(0, amount);
    }

    public static ActivityFact at(ActivityKind kind, Instant at, int amount) {
        return new ActivityFact(kind, at, null, amount);
    }

    /** Día al que pertenece, en la zona dada si solo se sabe el instante. */
    public LocalDate dayIn(ZoneId zone) {
        return day != null ? day : LocalDate.ofInstant(at, zone);
    }
}
