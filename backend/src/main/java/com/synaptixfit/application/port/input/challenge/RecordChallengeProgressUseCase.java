package com.synaptixfit.application.port.input.challenge;

import java.time.Instant;
import java.util.UUID;

/** Registra progreso manual en un reto sin tareas o en una tarea concreta. */
public interface RecordChallengeProgressUseCase {

    /** {@code recordedAt} nulo = ahora. */
    record Command(UUID userId, UUID challengeId, UUID milestoneId, double amount, Instant recordedAt) {}

    ChallengeOutcome recordProgress(Command command);
}
