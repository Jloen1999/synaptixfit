package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** Importación ICS: sin {@code url} se usa la de la asignatura; {@code force} importa aunque no coincida. */
public record IcsImportRequest(@NotNull UUID subjectId, @Size(max = 2048) String url, Boolean force) {
}
