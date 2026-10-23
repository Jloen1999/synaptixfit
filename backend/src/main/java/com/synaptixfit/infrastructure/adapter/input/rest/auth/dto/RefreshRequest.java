package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** Token de refresco para renovar o cerrar la sesión. */
public record RefreshRequest(@NotBlank String refreshToken) {
}
