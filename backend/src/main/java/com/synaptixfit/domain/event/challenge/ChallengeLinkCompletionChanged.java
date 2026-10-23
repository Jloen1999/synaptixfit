package com.synaptixfit.domain.event.challenge;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** Un reto o una tarea de reto vinculados a una entrega/examen han cambiado su estado. La entrega vinculada se sincroniza. */
public record ChallengeLinkCompletionChanged(UUID userId, String linkedEntityType, UUID linkedEntityId, boolean completed, Instant occurredAt) implements DomainEvent {
}
