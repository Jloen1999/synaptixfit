package com.synaptixfit.infrastructure.adapter.input.rest.privacy.dto;

import jakarta.validation.constraints.Size;

/**
 * Confirmación de la baja: {@code password} si la cuenta tiene contraseña; si solo usa Google,
 * {@code confirm = true}.
 */
public record DeleteAccountRequest(@Size(max = 200) String password, Boolean confirm) {
}
