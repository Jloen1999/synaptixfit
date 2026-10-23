package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.Priority;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/**
 * Alta de un bloque. {@code type} por defecto STUDY. En EXAM/DELIVERY sin {@code deadlineId} se crea la
 * entrega/examen con {@code deadlineTitle} (o los temas).
 */
public record CalendarBlockRequest(@NotNull Instant start, @NotNull Instant end, Boolean fixed, ActivityType type,
                                   UUID subjectId, @Size(max = 1000) String topics, @Size(max = 200) String location,
                                   Priority priority, Boolean privateBlock, ClassKind classKind, UUID routineId,
                                   UUID routineWeekId, UUID routineDayId, UUID challengeId, UUID milestoneId,
                                   UUID deadlineId, @Size(max = 200) String deadlineTitle, Priority deadlineDifficulty,
                                   @Schema(description = "Semanas siguientes en las que se repite (solo al crear)")
                                   @Min(0) @Max(CalendarBlock.MAX_WEEKLY_REPEATS) Integer repeatWeeks) {
}
