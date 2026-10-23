package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.Priority;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/** Alta de una entrega/examen. {@code difficulty} por defecto MEDIUM. */
public record DeadlineRequest(@NotBlank @Size(max = 200) String title, @NotNull DeadlineType type,
                              @NotNull Instant dueAt, Priority difficulty, @Size(max = 2000) String description,
                              UUID subjectId) {
}
