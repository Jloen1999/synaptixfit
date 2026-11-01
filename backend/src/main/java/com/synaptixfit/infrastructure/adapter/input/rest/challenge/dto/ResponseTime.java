package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/** Instante y día (en la zona de gamificación) con los que se arma una respuesta: estado y racha del día. */
public record ResponseTime(Instant now, LocalDate today) {

    public static ResponseTime of(Clock clock, ZoneId zone) {
        Instant now = clock.instant();
        return new ResponseTime(now, LocalDate.ofInstant(now, zone));
    }
}
