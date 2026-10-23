package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Cambio de contraseña. {@code currentPassword} es opcional si la cuenta solo usa Google. */
public record ChangePasswordRequest(String currentPassword, @NotBlank @Size(min = 8, max = 128) String newPassword) {
}
