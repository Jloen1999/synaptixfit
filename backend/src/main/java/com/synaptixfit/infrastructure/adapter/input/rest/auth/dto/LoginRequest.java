package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** Inicio de sesión con email y contraseña. */
public record LoginRequest(@NotBlank String email, @NotBlank String password) {
}
