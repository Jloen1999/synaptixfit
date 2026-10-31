package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Importación ICS: sin {@code url} se usa la de la asignatura; {@code force} importa aunque no coincida. Sin
 * {@code subjectId} es un calendario general (p. ej. el del Campus Virtual) y {@code url} es obligatoria.
 */
public record IcsImportRequest(UUID subjectId, @Size(max = 2048) String url, Boolean force) {
}
