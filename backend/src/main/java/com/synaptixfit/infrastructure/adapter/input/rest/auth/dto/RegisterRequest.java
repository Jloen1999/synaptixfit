package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Alta con email y contraseña. */
public record RegisterRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 128) String password,
        @NotBlank @Size(min = 2, max = 120) String fullName,
        // Versión de la política y las condiciones aceptadas en el registro (ADR 0034); opcional por las apps antiguas.
        @Size(max = 40) String acceptedLegalVersion) {
}
