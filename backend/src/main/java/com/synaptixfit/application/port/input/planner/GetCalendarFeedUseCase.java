package com.synaptixfit.application.port.input.planner;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Si el usuario tiene un enlace de suscripción activo y desde cuándo (el token no se puede volver a ver). */
public interface GetCalendarFeedUseCase {

    Optional<Instant> activeSince(UUID userId);
}
