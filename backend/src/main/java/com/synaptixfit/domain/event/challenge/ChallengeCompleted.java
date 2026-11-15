package com.synaptixfit.domain.event.challenge;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Un reto ha pasado a completado. Social puede publicarlo en el muro (tipo
 * {@code challenge_completed}), como hacía la app antigua al completar un reto.
 *
 * @param challengeType {@code FITNESS} o {@code ACADEMIC}
 * @param shareable     false si el reto se cuenta con datos de bienestar (ADR 0043): no se publica en el muro
 */
public record ChallengeCompleted(UUID userId, UUID challengeId, String title, String challengeType,
                                 Instant occurredAt, boolean shareable) implements DomainEvent {
}
