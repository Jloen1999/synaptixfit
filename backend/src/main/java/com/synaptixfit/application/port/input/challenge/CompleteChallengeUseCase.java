package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** Completa un reto (y sus tareas pendientes) otorgando su XP. Idempotente. */
public interface CompleteChallengeUseCase {

    ChallengeOutcome completeChallenge(UUID userId, UUID challengeId);
}
