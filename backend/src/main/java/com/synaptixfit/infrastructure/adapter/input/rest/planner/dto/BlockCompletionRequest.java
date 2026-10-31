package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * Marcar o desmarcar un bloque como hecho. {@code effort} (esfuerzo percibido 1-10, opcional) solo se usa
 * en los bloques de deporte sin rutina, para calcular su carga física.
 */
public record BlockCompletionRequest(@NotNull Boolean completed, @Min(1) @Max(10) Integer effort) {
}
