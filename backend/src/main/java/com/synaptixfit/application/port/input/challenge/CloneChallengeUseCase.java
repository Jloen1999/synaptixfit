package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import java.util.UUID;

/** Copia un reto visible (con sus tareas y dependencias) como reto privado del usuario. */
public interface CloneChallengeUseCase {

    Challenge cloneChallenge(UUID userId, UUID challengeId);
}
