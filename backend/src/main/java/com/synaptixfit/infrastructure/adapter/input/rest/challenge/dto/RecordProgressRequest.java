package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

/**
 * Progreso manual en puntos porcentuales (se suma al actual, con tope 100). {@code milestoneId}
 * es obligatorio si el reto tiene tareas; {@code recordedAt} nulo = ahora.
 */
public record RecordProgressRequest(UUID milestoneId,
                                    @NotNull @DecimalMin("0.01") @DecimalMax("100") Double amount,
                                    Instant recordedAt) {
}
