package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.Priority;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/** Edición parcial: los nulos no cambian; {@code clearSubject=true} quita la asignatura. */
public record DeadlineUpdateRequest(@Size(min = 1, max = 200) String title, DeadlineType type, Instant dueAt,
                                    Priority difficulty, @Size(max = 2000) String description, UUID subjectId,
                                    Boolean clearSubject) {
}
