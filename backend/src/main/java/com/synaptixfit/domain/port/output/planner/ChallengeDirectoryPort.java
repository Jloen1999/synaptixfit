package com.synaptixfit.domain.port.output.planner;

import java.util.UUID;

/** Comprobación de propiedad de retos y tareas de reto (módulo de gamificación). */
public interface ChallengeDirectoryPort {

    boolean ownsChallenge(UUID userId, UUID challengeId);

    boolean ownsMilestone(UUID userId, UUID milestoneId);
}
