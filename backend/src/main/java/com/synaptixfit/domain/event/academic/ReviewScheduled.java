package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Tras un repaso espaciado (SM-2) se ha fijado la siguiente fecha. El planificador crea en el
 * calendario un bloque de tipo 'repaso' no fijo para esa fecha (si no existe ya para el material).
 */
public record ReviewScheduled(UUID userId, UUID studyMaterialId, UUID subjectId, String title,
                              Instant dueAt, Instant occurredAt) implements DomainEvent {
}
