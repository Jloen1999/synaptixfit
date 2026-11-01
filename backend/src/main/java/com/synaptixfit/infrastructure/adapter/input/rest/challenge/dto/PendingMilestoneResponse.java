package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.PendingMilestone;
import java.time.Instant;
import java.util.UUID;

/** Tarea pendiente (disponible o en curso) de un reto en curso, con los datos básicos de su reto. */
public record PendingMilestoneResponse(UUID challengeId, String challengeTitle, Instant challengeEndAt,
                                       String challengeType, MilestoneResponse milestone) {

    public static PendingMilestoneResponse from(PendingMilestone p) {
        int xp = p.challenge().milestoneXp().getOrDefault(p.milestone().id(), 0);
        return new PendingMilestoneResponse(p.challenge().id(), p.challenge().title(), p.challenge().endAt(),
                p.challenge().type().name(), MilestoneResponse.from(p.challenge(), p.milestone(), xp, true));
    }
}
