package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Recommendation;
import java.util.UUID;

/** Aplica una sugerencia: copia sus ajustes a la rutina y la marca como aplicada. */
public interface ApplyRecommendationUseCase {

    Recommendation apply(UUID userId, UUID recommendationId);
}
