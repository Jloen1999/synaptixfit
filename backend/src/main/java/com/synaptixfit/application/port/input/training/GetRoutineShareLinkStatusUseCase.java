package com.synaptixfit.application.port.input.training;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Hasta cuándo vale el último enlace vigente de la rutina del dueño; vacío si no se está compartiendo (ADR 0043). */
public interface GetRoutineShareLinkStatusUseCase {

    Optional<Instant> sharedUntil(UUID userId, UUID routineId);
}
