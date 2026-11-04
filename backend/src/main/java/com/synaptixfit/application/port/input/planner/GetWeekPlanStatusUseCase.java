package com.synaptixfit.application.port.input.planner;

import java.time.LocalDate;
import java.util.UUID;

/**
 * ¿Está cerrada la semana? «Cerrar semana» se hace una vez: después, la app enseña «Semana cerrada» en lugar
 * del botón (los bloques nuevos se guardan solos). Cualquier día de la semana sirve como {@code weekStart}.
 */
public interface GetWeekPlanStatusUseCase {

    Status status(UUID userId, LocalDate weekStart);

    /** {@code weekStart}: el lunes; {@code xpAwarded}: la experiencia que dio al cerrarla (0 si no está cerrada). */
    record Status(LocalDate weekStart, boolean closed, int xpAwarded) {
    }
}
