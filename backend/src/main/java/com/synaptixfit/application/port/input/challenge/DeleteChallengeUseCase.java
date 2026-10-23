package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** Borra un reto con sus tareas y resta el XP que habían otorgado (anti-farmeo). */
public interface DeleteChallengeUseCase {

    void deleteChallenge(UUID userId, UUID challengeId);
}
