package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.FocusSession;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Fase Pomodoro terminada. {@code cycles} 1 y {@code completed} true por defecto; {@code date} hoy por
 * defecto. {@code blockId} (bloque propio en el que se hizo, no se completa) y {@code subjectId}
 * (asignatura propia; si falta, la del bloque) son opcionales.
 */
public record FocusSessionRequest(@NotNull FocusSession.FocusPhase phase, @NotNull @Min(1) @Max(180) Integer durationMinutes,
                                  @Min(1) @Max(20) Integer cycles, Boolean completed, LocalDate date, UUID blockId,
                                  UUID subjectId) {
}
