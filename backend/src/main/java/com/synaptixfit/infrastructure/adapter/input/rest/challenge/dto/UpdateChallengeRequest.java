package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.shared.Visibility;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/**
 * Edición parcial: los campos nulos no cambian. {@code clearSubject}/{@code clearLink}/
 * {@code clearSessionTarget} a true quitan la asignatura, el vínculo o el objetivo de sesiones.
 */
public record UpdateChallengeRequest(@Size(min = 5, max = 80) String title,
                                     ChallengeType type,
                                     @Size(max = 500) String goal,
                                     Visibility visibility,
                                     Difficulty difficulty,
                                     Instant startAt,
                                     Instant endAt,
                                     UUID subjectId,
                                     Boolean clearSubject,
                                     LinkType linkedEntityType,
                                     UUID linkedEntityId,
                                     Boolean clearLink,
                                     @Min(1) @Max(365) Integer sessionTarget,
                                     Boolean clearSessionTarget) {
}
