package com.synaptixfit.domain.event.social;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Dos personas dejan de ser amigas: {@code userId} bloquea a {@code otherUserId} ({@code blocked}) o elimina la
 * amistad. Lo compartido entre las dos (rachas, retos y entrenos con amigos, ADR 0044) se deja.
 */
public record FriendshipEnded(UUID userId, UUID otherUserId, boolean blocked, Instant occurredAt)
        implements DomainEvent {
}
