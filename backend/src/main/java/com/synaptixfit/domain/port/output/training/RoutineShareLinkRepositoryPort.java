package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.RoutineShareLink;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Enlaces para copiar rutinas (ADR 0043). Se buscan por la huella del token, nunca por el token en claro. */
public interface RoutineShareLinkRepositoryPort {

    RoutineShareLink save(RoutineShareLink link);

    Optional<RoutineShareLink> findByTokenHash(String tokenHash);

    /**
     * Bloquea la rutina hasta el final de la transacción (ADR 0045, cierre): dos «Compartir enlace» a la vez esperan
     * uno al otro y el segundo ya cuenta el enlace del primero, así no se pasa del tope de enlaces vigentes.
     */
    void lockRoutine(UUID routineId);

    /** Enlaces de la rutina sin revocar ni caducar en {@code now}. */
    List<RoutineShareLink> findActiveByRoutine(UUID routineId, Instant now);

    /** Revoca en {@code now} todos los enlaces vigentes de la rutina; devuelve cuántos. */
    int revokeAllOfRoutine(UUID routineId, Instant now);
}
