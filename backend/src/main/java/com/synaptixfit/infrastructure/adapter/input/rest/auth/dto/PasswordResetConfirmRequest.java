package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Contraseña nueva con el token del enlace del correo. */
public record PasswordResetConfirmRequest(@NotBlank @Size(max = 128) String token,
                                          @NotBlank @Size(min = 8, max = 128) String newPassword) {

    @Override
    public String toString() {
        return "PasswordResetConfirmRequest[***]";
    }
}
