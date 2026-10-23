package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import jakarta.validation.constraints.NotNull;

/** Activar o desactivar el modo bloqueo. */
public record SetLockdownRequest(@NotNull Boolean active) {
}
