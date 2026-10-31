package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import java.time.Instant;

/** DTO de la suscripción al calendario. */
public final class CalendarFeedDtos {

    private CalendarFeedDtos() {
    }

    /** Estado del enlace; {@code activeSince} nulo si no hay ninguno. */
    public record CalendarFeedStatusResponse(boolean active, Instant activeSince) {
    }

    /** Enlace recién creado: el token solo se ve ahora (el cliente compone la URL con su dirección de la API). */
    public record CalendarFeedCreatedResponse(String token, Instant createdAt) {
    }
}
