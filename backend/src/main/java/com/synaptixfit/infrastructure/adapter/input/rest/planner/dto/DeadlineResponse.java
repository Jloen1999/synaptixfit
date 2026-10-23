package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.Priority;
import java.time.Instant;
import java.util.UUID;

/** Entrega, examen, presentación u otra evaluación. {@code imported}: viene de un ICS. */
public record DeadlineResponse(UUID id, String title, DeadlineType type, Instant dueAt, Priority difficulty,
                               String description, UUID subjectId, boolean completed, boolean xpAwarded,
                               UUID studyPlanId, boolean imported, Instant createdAt, Instant updatedAt) {

    public static DeadlineResponse from(Deadline d) {
        return new DeadlineResponse(d.id(), d.title(), d.type(), d.dueAt(), d.difficulty(), d.description(),
                d.subjectId(), d.completed(), d.xpAwarded(), d.studyPlanId(), d.icsUid() != null, d.createdAt(),
                d.updatedAt());
    }
}
