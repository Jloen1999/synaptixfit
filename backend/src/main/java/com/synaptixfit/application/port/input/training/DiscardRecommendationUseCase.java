package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Descarta (borra) una sugerencia. */
public interface DiscardRecommendationUseCase {

    void discard(UUID userId, UUID recommendationId);
}
