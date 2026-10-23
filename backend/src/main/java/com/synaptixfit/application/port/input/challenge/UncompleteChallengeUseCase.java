package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** Descompleta un reto y sus tareas restando exactamente el XP otorgado. Idempotente. */
public interface UncompleteChallengeUseCase {

    ChallengeOutcome uncompleteChallenge(UUID userId, UUID challengeId);
}
