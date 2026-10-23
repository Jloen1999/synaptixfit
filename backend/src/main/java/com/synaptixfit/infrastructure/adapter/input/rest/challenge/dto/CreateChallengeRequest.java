package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.model.shared.Visibility;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Alta de un reto. Sin {@code type} se deduce de la asignatura; sin {@code goal} se usa el título;
 * sin {@code startAt} empieza ahora. {@code sessionTarget} (solo FITNESS y sin tareas): el reto se
 * completa solo al llegar a ese número de sesiones de entrenamiento completadas en su periodo.
 */
public record CreateChallengeRequest(@NotBlank @Size(min = 5, max = 80) String title,
                                     ChallengeType type,
                                     @Size(max = 500) String goal,
                                     Visibility visibility,
                                     Difficulty difficulty,
                                     Instant startAt,
                                     @NotNull Instant endAt,
                                     UUID subjectId,
                                     LinkType linkedEntityType,
                                     UUID linkedEntityId,
                                     @Valid @Size(max = 12) List<MilestoneRequest> milestones,
                                     @Min(1) @Max(365) Integer sessionTarget) {

    public ChallengeDetails toDetails(Instant now) {
        return new ChallengeDetails(title, type, goal, visibility, difficulty, startAt == null ? now : startAt, endAt,
                subjectId, Links.of(linkedEntityType, linkedEntityId), sessionTarget);
    }

    public List<MilestoneDraft> toDrafts() {
        return milestones == null ? List.of() : milestones.stream().map(MilestoneRequest::toDraft).toList();
    }
}
