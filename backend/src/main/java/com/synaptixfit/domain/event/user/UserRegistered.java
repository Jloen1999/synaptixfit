package com.synaptixfit.domain.event.user;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** Se ha creado una cuenta nueva (inicialización de estados por defecto). */
public record UserRegistered(UUID userId, Instant occurredAt) implements DomainEvent {
}
