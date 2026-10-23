package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.WeekBalance;
import java.time.LocalDate;

/** Balance estudio/deporte de la semana (horas planificadas y completadas). */
public record WeekBalanceResponse(LocalDate weekStart, double plannedStudyHours, double actualStudyHours,
                                  double plannedSportHours, double actualSportHours, WeekBalance.State state) {

    public static WeekBalanceResponse from(LocalDate weekStart, WeekBalance b) {
        return new WeekBalanceResponse(weekStart, b.plannedStudyHours(), b.actualStudyHours(), b.plannedSportHours(),
                b.actualSportHours(), b.state());
    }
}
