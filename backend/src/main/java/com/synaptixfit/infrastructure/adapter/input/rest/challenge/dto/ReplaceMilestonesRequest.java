package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/** Nueva lista completa de tareas (vacía = reto sin tareas). */
public record ReplaceMilestonesRequest(@NotNull @Valid @Size(max = 12) List<MilestoneRequest> milestones) {
}
