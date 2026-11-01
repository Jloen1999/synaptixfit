package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import java.time.Instant;
import java.util.UUID;

/**
 * Progreso manual en puntos porcentuales. {@code value} fija el valor absoluto («¿cuánto llevas?»); si no
 * llega, {@code amount} se suma al actual con tope 100 (forma anterior, para clientes ya instalados). Uno de
 * los dos es obligatorio. {@code milestoneId} es obligatorio si el reto tiene tareas; {@code recordedAt}
 * nulo = ahora.
 */
public record RecordProgressRequest(UUID milestoneId,
                                    @DecimalMin("0.01") @DecimalMax("100") Double amount,
                                    @DecimalMin("0") @DecimalMax("100") Double value,
                                    Instant recordedAt) {
}
