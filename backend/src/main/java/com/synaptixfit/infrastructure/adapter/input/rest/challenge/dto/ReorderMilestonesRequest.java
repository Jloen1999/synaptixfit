package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;

/** Ids de todas las tareas del reto en el nuevo orden. */
public record ReorderMilestonesRequest(@NotNull List<@NotNull UUID> milestoneIds) {
}
