package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Recommendation;
import java.util.UUID;

/** Sugerencias del usuario; {@code applied} nulo no filtra. */
public interface ListRecommendationsUseCase {

    PageResult<Recommendation> list(UUID userId, Boolean applied, PageRequest page);
}
