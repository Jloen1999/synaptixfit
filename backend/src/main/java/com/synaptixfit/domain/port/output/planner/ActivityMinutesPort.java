package com.synaptixfit.domain.port.output.planner;

import java.util.Optional;
import java.util.UUID;

/**
 * Minutos reales de la actividad apuntada en un evento de deporte (carrera GPS, a mano o al hacer un entreno de
 * carrera). Lo usa el planificador al volver a marcar un evento: la carga física cuenta lo hecho, no lo que ocupa
 * el evento en el calendario (ADR 0037).
 */
@FunctionalInterface
public interface ActivityMinutesPort {

    /** Vacío si el evento no tiene actividad apuntada. */
    Optional<Integer> realMinutes(UUID userId, UUID blockId);
}
