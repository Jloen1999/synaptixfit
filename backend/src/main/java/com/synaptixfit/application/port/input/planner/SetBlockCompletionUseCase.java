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

    Result setCompletion(UUID userId, UUID blockId, boolean completed);
}
