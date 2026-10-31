package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Pedir el correo para restablecer la contraseña. */
public record PasswordResetRequest(@NotBlank @Email @Size(max = 254) String email) {
}
