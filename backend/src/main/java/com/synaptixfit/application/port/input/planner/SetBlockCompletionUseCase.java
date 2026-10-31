package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.util.UUID;

/**
 * Marca o desmarca un bloque como completado: experiencia {@code ceil(min/30)×10} una sola vez (se
 * resta al desmarcar), gasto calórico y carga cognitiva del bloque, asistencia si es una clase, y
 * evento {@code StudyBlockCompletionChanged}. Idempotente.
 */
public interface SetBlockCompletionUseCase {

    /** @param xpDelta experiencia sumada (positiva) o restada (negativa) por esta operación */
    record Result(CalendarBlock block, int xpDelta) {
    }

    /**
     * @param effort esfuerzo percibido (1-10) de un bloque de deporte sin rutina, para su carga física;
     *               null en los demás o si no se indica
     */
    Result setCompletion(UUID userId, UUID blockId, boolean completed, Integer effort);

    default Result setCompletion(UUID userId, UUID blockId, boolean completed) {
        return setCompletion(userId, blockId, completed, null);
    }
}
