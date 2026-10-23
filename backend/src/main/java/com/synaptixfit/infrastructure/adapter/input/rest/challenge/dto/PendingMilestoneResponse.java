package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.PendingMilestone;
import java.time.Instant;
import java.util.UUID;

/** Tarea pendiente (disponible o en curso) con los datos básicos de su reto. */
public record PendingMilestoneResponse(UUID challengeId, String challengeTitle, Instant challengeEndAt,
                                       MilestoneResponse milestone) {

    public static PendingMilestoneResponse from(PendingMilestone p) {
        return new PendingMilestoneResponse(p.challenge().id(), p.challenge().title(), p.challenge().endAt(),
                MilestoneResponse.from(p.milestone()));
    }
}
