package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.TimelineItem;
import java.time.Instant;
import java.util.UUID;

/** Elemento de la línea de tiempo: un bloque ({@code blockType}) o una entrega ({@code deadlineType}). */
public record TimelineItemResponse(TimelineItem.Kind kind, UUID id, ActivityType blockType, DeadlineType deadlineType,
                                   String title, Instant start, Instant end, UUID subjectId, String subjectName,
                                   boolean completed, boolean fixed, boolean immovable, String location,
                                   UUID deadlineId, UUID challengeId, UUID milestoneId, UUID routineId,
                                   UUID routineDayId) {

    public static TimelineItemResponse from(TimelineItem i) {
        return new TimelineItemResponse(i.kind(), i.id(), i.blockType(), i.deadlineType(), i.title(), i.start(),
                i.end(), i.subjectId(), i.subjectName(), i.completed(), i.fixed(), i.immovable(), i.location(),
                i.deadlineId(), i.challengeId(), i.milestoneId(), i.routineId(), i.routineDayId());
    }
}
