package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.RoutineRef;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Lectura de rutinas, semanas y días (módulo de entrenamiento). */
public interface RoutineDirectoryPort {

    /** La rutina (no eliminada) del usuario con sus días ordenados por semana y día. */
    Optional<RoutineRef> findOwnedWithDays(UUID userId, UUID routineId);

    /** Rutinas activas más recientes (sin días). */
    List<RoutineRef> findActive(UUID userId, int limit);
}
