package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** Detalle de un reto propio o de un reto ajeno visible para el usuario. */
public interface GetChallengeUseCase {

    ChallengeView getChallenge(UUID userId, UUID challengeId);
}
