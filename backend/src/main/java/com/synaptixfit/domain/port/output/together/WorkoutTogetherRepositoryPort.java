package com.synaptixfit.domain.port.output.together;

import com.synaptixfit.domain.model.together.WorkoutTogether;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** «Entrenamos juntos» y sus personas (tablas {@code entrenos_juntos} y {@code entrenos_juntos_miembros}, ADR 0044). */
public interface WorkoutTogetherRepositoryPort {

    Optional<WorkoutTogether> findById(UUID id);

    /**
     * El entreno bloqueado hasta el final de la transacción (ADR 0045): quien lo cambia lo lee así, porque guardar escribe
     * a todas las personas y dos acciones a la vez (dos que aceptan, una que sale y otra que reacciona) se pisarían.
     */
    Optional<WorkoutTogether> findByIdForUpdate(UUID id);

    WorkoutTogether save(WorkoutTogether workout);

    /** Los de {@code from} en adelante en los que {@code userId} está invitado o dentro. */
    List<WorkoutTogether> findVisibleTo(UUID userId, LocalDate from);

    /** El que usa esa sesión de entrenamiento, si hay alguno. */
    Optional<WorkoutTogether> findBySession(UUID sessionId);
}
