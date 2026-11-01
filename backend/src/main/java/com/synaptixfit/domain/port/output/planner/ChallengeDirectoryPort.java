package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.ChallengeRef;
import java.util.Optional;
import java.util.UUID;

/** Retos y tareas de reto del usuario (módulo de gamificación, solo lectura) para asignarles bloques. */
public interface ChallengeDirectoryPort {

    /** Reto propio con su periodo; vacío si no existe o es ajeno. */
    Optional<ChallengeRef> findOwnedChallenge(UUID userId, UUID challengeId);

    /** Reto propio al que pertenece la tarea; vacío si la tarea no existe o es ajena. */
    Optional<UUID> findMilestoneChallenge(UUID userId, UUID milestoneId);
}
