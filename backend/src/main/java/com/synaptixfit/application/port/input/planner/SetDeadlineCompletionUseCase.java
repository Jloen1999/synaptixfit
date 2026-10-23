package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import java.util.UUID;

/**
 * Marca o desmarca una entrega como completada: 30 de experiencia una sola vez (se restan al
 * desmarcar) y evento {@code DeadlineCompletionChanged}. Idempotente.
 */
public interface SetDeadlineCompletionUseCase {

    /** @param xpDelta experiencia sumada o restada por esta operación */
    record Result(Deadline deadline, int xpDelta) {
    }

    Result setCompletion(UUID userId, UUID deadlineId, boolean completed);
}
