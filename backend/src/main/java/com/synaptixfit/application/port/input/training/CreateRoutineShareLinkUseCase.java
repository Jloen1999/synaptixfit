package com.synaptixfit.application.port.input.training;

import java.time.Instant;
import java.util.UUID;

/** El dueño crea un enlace para que otra persona copie su rutina (ADR 0043). El token solo se ve esta vez. */
public interface CreateRoutineShareLinkUseCase {

    record Created(String token, Instant expiresAt) {
    }

    Created createShareLink(UUID userId, UUID routineId);
}
