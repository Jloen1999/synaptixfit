package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/** Borra los bloques de repaso pendientes de un material que ya no se repasa. Idempotente. */
public interface CancelReviewBlocksUseCase {

    void cancelReviewBlocks(UUID userId, UUID studyMaterialId);
}
