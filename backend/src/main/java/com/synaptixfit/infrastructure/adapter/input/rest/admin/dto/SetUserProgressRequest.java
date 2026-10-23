package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/** Nivel y experiencia dentro del nivel (debe ser menor que 100 × nivel). */
public record SetUserProgressRequest(@NotNull @Min(1) @Max(1000) Integer level,
                                     @NotNull @Min(0) Integer levelXp) {
}
