package com.synaptixfit.domain.port.output.training;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Lectura de los bloques del calendario enlazados a los días de una rutina (tabla del Planificador),
 * para proponer la fecha del próximo día con la que ya está en el calendario.
 */
public interface RoutineCalendarPort {

    /** Inicio de los bloques pendientes (no completados) de cada día de la rutina, por día. */
    Map<UUID, List<Instant>> pendingBlockStarts(UUID userId, UUID routineId);
}
