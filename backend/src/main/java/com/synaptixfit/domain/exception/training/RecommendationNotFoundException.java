package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La sugerencia no existe o no es del usuario. */
public class RecommendationNotFoundException extends ResourceNotFoundException {

    public RecommendationNotFoundException(Object id) {
        super("TRAINING_RECOMMENDATION_NOT_FOUND", "Training recommendation", id);
    }
}
