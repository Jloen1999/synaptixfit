package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import jakarta.validation.constraints.NotNull;

/** Activar o desactivar el shadowban. */
public record SetShadowbanRequest(@NotNull Boolean shadowbanned) {
}
