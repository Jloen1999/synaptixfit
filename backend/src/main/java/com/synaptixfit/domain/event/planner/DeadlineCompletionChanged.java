package com.synaptixfit.domain.event.planner;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** Una entrega o examen ha cambiado su estado de completado. Retos y tareas vinculados se sincronizan. */
public record DeadlineCompletionChanged(UUID userId, UUID deadlineId, boolean completed, Instant occurredAt) implements DomainEvent {
}
