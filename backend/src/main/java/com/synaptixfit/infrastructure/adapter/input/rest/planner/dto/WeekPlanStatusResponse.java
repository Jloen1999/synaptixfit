package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.GetWeekPlanStatusUseCase;
import java.time.LocalDate;

/** Estado de «Cerrar semana»: {@code closed} si ya se cerró y la experiencia que dio. */
public record WeekPlanStatusResponse(LocalDate weekStart, boolean closed, int xpAwarded) {

    public static WeekPlanStatusResponse from(GetWeekPlanStatusUseCase.Status s) {
        return new WeekPlanStatusResponse(s.weekStart(), s.closed(), s.xpAwarded());
    }
}
