package com.synaptixfit.domain.event.badge;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** El usuario ha obtenido una insignia. Social puede publicarlo (tipo {@code badge_unlocked}). */
public record BadgeEarned(UUID userId, UUID badgeId, String badgeName, Instant occurredAt) implements DomainEvent {
}
