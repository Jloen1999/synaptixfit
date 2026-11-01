package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.application.port.input.challenge.ChallengeOutcome;
import java.util.List;
import java.util.UUID;

/**
 * Resultado de una acción: el reto actualizado, el XP neto aplicado (negativo si se ha restado),
 * las tareas desbloqueadas y si el reto acaba de completarse.
 */
public record ChallengeOutcomeResponse(ChallengeResponse challenge, int xpDelta, List<UUID> unlockedMilestoneIds,
                                       boolean challengeCompleted) {

    public static ChallengeOutcomeResponse from(ChallengeOutcome o, ResponseTime time) {
        return new ChallengeOutcomeResponse(ChallengeResponse.own(o.challenge(), time), o.xpDelta(),
                o.unlockedMilestoneIds(), o.challengeCompleted());
    }
}
