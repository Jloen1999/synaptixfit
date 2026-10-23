package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** Inicio de sesión con el ID token obtenido por Google Sign-In en el cliente. */
public record GoogleLoginRequest(@NotBlank String idToken) {
}
