package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Objetivos de la semana para las sugerencias. Semana actual por defecto; 60 min por sesión de
 * deporte y bloques de estudio de hasta 90 min por defecto.
 */
public record SuggestionRequest(LocalDate weekStart, @NotNull @DecimalMin("0") @DecimalMax("80") Double studyHours,
                                @NotNull @Min(0) @Max(7) Integer sportSessions,
                                @Min(30) @Max(120) Integer minutesPerSportSession,
                                @Min(30) @Max(240) Integer maxStudyBlockMinutes) {
}
