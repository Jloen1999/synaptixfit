package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** Descompleta una tarea restando su XP. Idempotente. */
public interface UncompleteMilestoneUseCase {

    ChallengeOutcome uncompleteMilestone(UUID userId, UUID challengeId, UUID milestoneId);
}
