package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.Priority;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** Sustitución completa de los datos editables de un bloque (sin horario). {@code type} nulo conserva el actual. */
public record BlockDetailsRequest(ActivityType type, UUID subjectId, @Size(max = 1000) String topics,
                                  @Size(max = 200) String location, Priority priority, Boolean privateBlock,
                                  ClassKind classKind, UUID routineId, UUID routineWeekId, UUID routineDayId,
                                  UUID challengeId, UUID milestoneId, UUID deadlineId) {
}
