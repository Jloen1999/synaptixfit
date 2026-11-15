package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** «Dejar de compartir»: el dueño revoca todos los enlaces vigentes de su rutina (ADR 0043). Idempotente. */
public interface RevokeRoutineShareLinksUseCase {

    void revokeShareLinks(UUID userId, UUID routineId);
}
