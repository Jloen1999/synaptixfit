package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ConflictException;

/** La sugerencia ya se aplicó. */
public class RecommendationAlreadyAppliedException extends ConflictException {

    public RecommendationAlreadyAppliedException() {
        super("TRAINING_RECOMMENDATION_APPLIED", "The recommendation was already applied");
    }
}
