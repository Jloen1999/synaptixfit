package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** Completa una tarea desbloqueada otorgando su XP. Idempotente. */
public interface CompleteMilestoneUseCase {

    ChallengeOutcome completeMilestone(UUID userId, UUID challengeId, UUID milestoneId);
}
