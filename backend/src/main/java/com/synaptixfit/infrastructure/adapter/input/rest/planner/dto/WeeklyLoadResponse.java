package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import java.time.LocalDate;
import java.util.UUID;

/** Carga académica de una semana (lunes). */
public record WeeklyLoadResponse(UUID id, LocalDate weekStart, int plannedHours, int actualHours, int exams,
                                 int deliveries, int stressLevel, double sleepHours, String notes, boolean xpAwarded) {

    public static WeeklyLoadResponse from(WeeklyAcademicLoad l) {
        return new WeeklyLoadResponse(l.id(), l.weekStart(), l.plannedHours(), l.actualHours(), l.exams(),
                l.deliveries(), l.stressLevel(), l.sleepHours(), l.notes(), l.xpAwarded());
    }
}
