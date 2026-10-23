package com.synaptixfit.infrastructure.adapter.input.rest.badge.dto;

import jakarta.validation.constraints.NotNull;

/** Mostrar u ocultar una insignia obtenida. */
public record BadgeVisibilityRequest(@NotNull Boolean visible) {
}
