package com.synaptixfit.domain.event;

import java.time.Instant;

/**
 * Hecho de negocio ya ocurrido que otros módulos pueden necesitar.
 *
 * <p>Sustituye a los triggers que acoplaban tablas de módulos distintos. Se publica de forma
 * síncrona dentro de la misma transacción: si un oyente falla, se deshace toda la operación.
 * Los oyentes deben ser idempotentes (solo actúan si el estado cambia).
 */
public interface DomainEvent {

    Instant occurredAt();
}
