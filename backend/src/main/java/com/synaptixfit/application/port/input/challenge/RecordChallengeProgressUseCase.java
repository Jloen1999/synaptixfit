package com.synaptixfit.application.port.input.challenge;

import java.time.Instant;
import java.util.UUID;

/**
 * Registra progreso manual en un reto sin tareas o en una tarea concreta. Con {@code value} se fija el valor
 * absoluto («llevas 40 % → pon 60 %»); sin él, {@code amount} se suma al actual (clientes anteriores).
 */
public interface RecordChallengeProgressUseCase {

    /** {@code recordedAt} nulo = ahora; {@code value} nulo = sumar {@code amount}. */
    record Command(UUID userId, UUID challengeId, UUID milestoneId, Double amount, Double value, Instant recordedAt) {}

    ChallengeOutcome recordProgress(Command command);
}
