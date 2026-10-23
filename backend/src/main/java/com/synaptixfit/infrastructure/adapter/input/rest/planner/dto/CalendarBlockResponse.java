package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.Priority;
import java.time.Instant;
import java.util.UUID;

/** Bloque del calendario. {@code imported}: viene de un ICS o de un escaneo de horario. */
public record CalendarBlockResponse(UUID id, ActivityType type, Instant start, Instant end, int dayOfWeek,
                                    UUID subjectId, String topics, String location, Priority priority,
                                    boolean privateBlock, ClassKind classKind, boolean fixed, boolean immovable,
                                    boolean imported, boolean hasConflict, boolean completed,
                                    Instant attendanceRegisteredAt, boolean xpAwarded, int xpReward, Double metValue,
                                    Double caloriesBurned, Double cognitiveLoad, UUID studyPlanId, UUID routineId,
                                    UUID routineWeekId, UUID routineDayId, UUID challengeId, UUID milestoneId,
                                    UUID deadlineId, UUID studyMaterialId, Instant createdAt) {

    public static CalendarBlockResponse from(CalendarBlock b) {
        CalendarBlock.Details d = b.details();
        return new CalendarBlockResponse(b.id(), b.type(), b.start(), b.end(), b.dayOfWeek(), d.subjectId(),
                d.topics(), d.location(), d.priority(), d.isPrivate(), d.classKind(), b.fixed(), b.immovable(),
                b.icsUid() != null, b.hasConflict(), b.completed(), b.attendanceRegisteredAt(), b.xpAwarded(),
                b.experienceReward(), b.metValue(), b.caloriesBurned(), b.cognitiveLoad(), b.studyPlanId(),
                d.routineId(), d.routineWeekId(), d.routineDayId(), d.challengeId(), d.milestoneId(), d.deadlineId(),
                b.studyMaterialId(), b.createdAt());
    }
}
