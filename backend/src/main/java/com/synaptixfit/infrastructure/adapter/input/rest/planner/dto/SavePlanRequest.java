package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.shared.Visibility;
import jakarta.validation.constraints.Size;

/** Guardado del plan semanal; ambos opcionales (nombre por defecto «Plan d/M», visibilidad PRIVATE). */
public record SavePlanRequest(@Size(min = 2, max = 120) String name, Visibility visibility) {
}
