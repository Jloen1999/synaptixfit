package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.SessionAdaptation;
import java.util.Map;
import java.util.UUID;

/**
 * Cómo se adapta hoy una sesión propia por examen cercano, sobreentrenamiento o fatiga del registro diario,
 * con las series que tocan a cada ejercicio planificado del día (sin cambios si no hay motivo).
 */
public interface GetSessionAdaptationUseCase {

    /** @param sets series de hoy por ejercicio planificado (vacío en una sesión libre) */
    record Result(SessionAdaptation adaptation, Map<UUID, Integer> sets) {
    }

    Result adaptation(UUID userId, UUID sessionId, String timeZone);
}
