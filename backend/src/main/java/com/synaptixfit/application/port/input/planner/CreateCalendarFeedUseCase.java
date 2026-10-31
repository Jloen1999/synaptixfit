package com.synaptixfit.application.port.input.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Crea el enlace privado de suscripción al calendario del usuario (si ya tenía uno, el anterior deja de
 * funcionar). El token en claro solo se devuelve aquí.
 */
public interface CreateCalendarFeedUseCase {

    record Result(String token, Instant createdAt) {
    }

    Result createFeed(UUID userId);
}
