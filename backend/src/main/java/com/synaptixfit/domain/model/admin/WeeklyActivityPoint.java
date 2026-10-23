package com.synaptixfit.domain.model.admin;

import java.time.LocalDate;

/** Actividad de un usuario en una semana (de lunes a domingo, UTC). */
public record WeeklyActivityPoint(LocalDate weekStart, int trainingSessions, int trainingMinutes, int calories,
                                  Double averageRpe, int studyMinutes, int focusMinutes) {
}
