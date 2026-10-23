package com.synaptixfit.domain.event.planner;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** Un bloque del calendario se ha marcado o desmarcado como completado (coste cognitivo y calórico, progreso de tareas de reto vinculadas). */
public record StudyBlockCompletionChanged(UUID userId, UUID blockId, String activityType, UUID subjectId, UUID challengeMilestoneId, Instant start, Instant end, boolean completed, Instant occurredAt) implements DomainEvent {
}
