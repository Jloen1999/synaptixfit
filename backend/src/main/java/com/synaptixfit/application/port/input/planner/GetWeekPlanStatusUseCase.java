package com.synaptixfit.application.port.input.planner;

import java.time.LocalDate;
import java.util.UUID;

/**
 * ¿Tiene ya plan la semana? Solo lo usan las apps anteriores al ADR 0038, que enseñaban «Cerrar semana»; la
 * actual ya no tiene ese botón (la experiencia de planificar llega sola). Cualquier día sirve como {@code weekStart}.
 */
public interface GetWeekPlanStatusUseCase {

    Status status(UUID userId, LocalDate weekStart);

    /** {@code weekStart}: el lunes; {@code xpAwarded}: la experiencia que dio al cerrarla (0 si no está cerrada). */
    record Status(LocalDate weekStart, boolean closed, int xpAwarded) {
    }
}
