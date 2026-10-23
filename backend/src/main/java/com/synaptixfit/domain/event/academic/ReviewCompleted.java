package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Se ha hecho un repaso espaciado (SM-2) de un material. El planificador completa su bloque de
 * repaso pendiente (sin XP de bloque: la da el repaso), Indicadores recalculan la carga cognitiva y
 * Gamificación evalúa insignias. Se publica antes de {@link ReviewScheduled}.
 */
public record ReviewCompleted(UUID userId, UUID studyMaterialId, UUID subjectId, int quality, int xpAwarded,
                              Instant occurredAt) implements DomainEvent {
}
