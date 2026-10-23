package com.synaptixfit.domain.event.insights;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** El ACWR acaba de entrar en zona de sobreentrenamiento (antes estaba fuera). Notificaciones avisa. */
public record OvertrainingDetected(UUID userId, double acwr, Instant occurredAt) implements DomainEvent {
}
