package com.synaptixfit.domain.event.gamification;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** El usuario ha subido de nivel al ganar experiencia. Notificaciones lo celebra. */
public record LevelUp(UUID userId, int level, Instant occurredAt) implements DomainEvent {
}
