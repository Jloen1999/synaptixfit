package com.synaptixfit.domain.model.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Elemento unificado de la línea de tiempo: un bloque del calendario o una entrega/examen.
 *
 * @param blockType    tipo del bloque (solo {@link Kind#BLOCK})
 * @param deadlineType tipo de la entrega (solo {@link Kind#DEADLINE})
 * @param end          fin del bloque; en una entrega coincide con la fecha límite
 */
public record TimelineItem(Kind kind, UUID id, ActivityType blockType, DeadlineType deadlineType, String title,
                           Instant start, Instant end, UUID subjectId, String subjectName, boolean completed,
                           boolean fixed, boolean immovable, String location, UUID deadlineId,
                           UUID challengeId, UUID milestoneId, UUID routineId, UUID routineDayId) {

    /** Origen del elemento. */
    public enum Kind {
        BLOCK,
        DEADLINE
    }
}
