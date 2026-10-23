package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

/** Estrés (1-10), sueño medio (0-14 h) y notas de la semana; los nulos no cambian. */
public record WellbeingRequest(@Min(1) @Max(10) Integer stressLevel,
                               @DecimalMin("0") @DecimalMax("14") Double sleepHours,
                               @Size(max = 2000) String notes) {
}
