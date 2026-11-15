package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Se ha apuntado o quitado una serie de una sesión en curso. «Entrenamos juntos» avisa en directo al grupo para que
 * su panel de «quién lleva cada ejercicio» se actualice al momento (ADR 0047).
 */
public record TrainingSessionProgressed(UUID userId, UUID sessionId, Instant occurredAt) implements DomainEvent {
}
