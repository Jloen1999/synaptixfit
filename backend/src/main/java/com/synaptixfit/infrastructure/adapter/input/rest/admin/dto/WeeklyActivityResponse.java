package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.WeeklyActivityPoint;
import java.time.LocalDate;

/** Actividad semanal de un usuario (semana de lunes a domingo, UTC). */
public record WeeklyActivityResponse(LocalDate weekStart, int trainingSessions, int trainingMinutes, int calories,
                                     Double averageRpe, int studyMinutes, int focusMinutes) {

    public static WeeklyActivityResponse from(WeeklyActivityPoint p) {
        return new WeeklyActivityResponse(p.weekStart(), p.trainingSessions(), p.trainingMinutes(), p.calories(),
                p.averageRpe(), p.studyMinutes(), p.focusMinutes());
    }
}
