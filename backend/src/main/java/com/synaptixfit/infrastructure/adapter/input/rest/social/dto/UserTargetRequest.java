package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Usuario destino de una solicitud de amistad o de un bloqueo. */
public record UserTargetRequest(@NotNull UUID userId) {
}
