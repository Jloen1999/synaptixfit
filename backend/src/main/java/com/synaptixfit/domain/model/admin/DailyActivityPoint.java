package com.synaptixfit.domain.model.admin;

import java.time.LocalDate;

/** Tendencia diaria de la plataforma: altas, usuarios activos y sesiones de entrenamiento (UTC). */
public record DailyActivityPoint(LocalDate date, long signups, long activeUsers, long trainingSessions) {
}
