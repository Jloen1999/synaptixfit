package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Set;
import java.util.UUID;

/**
 * Distribución de una rutina: días de la semana (1 = lunes … 7 = domingo; sin ellos, el preferido de
 * cada día de la rutina), fecha de inicio (hoy por defecto), hora preferida (08:00 por defecto) y
 * duración de cada sesión (60 min por defecto). Sustituye los bloques futuros pendientes de la rutina.
 */
public record RoutineDistributionRequest(@NotNull UUID routineId, Set<@Min(1) @Max(7) Integer> weekdays,
                                         LocalDate startDate, LocalTime preferredStart,
                                         @Min(30) @Max(240) Integer durationMinutes) {
}
