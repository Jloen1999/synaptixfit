package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** Un test de práctica ha terminado. Indicadores recalculan la carga cognitiva; Gamificación evalúa insignias. */
public record TestSessionCompleted(UUID userId, UUID testSessionId, UUID studyMaterialId, int score,
                                   int totalQuestions, Instant occurredAt) implements DomainEvent {
}
