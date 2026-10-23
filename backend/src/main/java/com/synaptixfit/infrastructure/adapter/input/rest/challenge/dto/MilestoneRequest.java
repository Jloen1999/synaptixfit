package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.model.challenge.UnlockCondition;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * Tarea de un reto. {@code id} solo al reemplazar tareas existentes (conserva su progreso);
 * {@code dependsOn} son posiciones (base 0) de otras tareas de la misma lista; {@code weight}
 * nulo en todas reparte 100 a partes iguales.
 */
public record MilestoneRequest(UUID id,
                               @NotBlank @Size(min = 3, max = 80) String title,
                               @DecimalMin("0.01") @DecimalMax("100") Double weight,
                               Difficulty difficulty,
                               UUID subjectId,
                               UUID noteId,
                               UUID fileId,
                               LinkType linkedEntityType,
                               UUID linkedEntityId,
                               @Size(max = 11) List<@NotNull @Min(0) Integer> dependsOn,
                               UnlockCondition conditionType,
                               @Min(1) Integer conditionN) {

    public MilestoneDraft toDraft() {
        return new MilestoneDraft(id, title, weight, difficulty, subjectId, noteId, fileId,
                Links.of(linkedEntityType, linkedEntityId), dependsOn, conditionType, conditionN);
    }
}
