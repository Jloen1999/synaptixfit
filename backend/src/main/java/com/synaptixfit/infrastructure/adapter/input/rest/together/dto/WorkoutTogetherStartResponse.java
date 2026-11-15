package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import java.util.UUID;

/** Sesión con la que la persona entrena juntos (la abre la sesión en vivo de siempre). */
public record WorkoutTogetherStartResponse(UUID sessionId) {
}
