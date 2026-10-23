package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.DailyActivityPoint;
import java.time.LocalDate;

/** Punto de la tendencia diaria. */
public record DailyActivityResponse(LocalDate date, long signups, long activeUsers, long trainingSessions) {

    public static DailyActivityResponse from(DailyActivityPoint p) {
        return new DailyActivityResponse(p.date(), p.signups(), p.activeUsers(), p.trainingSessions());
    }
}
