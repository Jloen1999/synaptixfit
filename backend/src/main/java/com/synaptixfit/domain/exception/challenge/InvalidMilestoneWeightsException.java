package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Los pesos de las tareas deben ser positivos y sumar 100. */
public class InvalidMilestoneWeightsException extends BusinessRuleException {

    public InvalidMilestoneWeightsException(String message) {
        super("MILESTONE_WEIGHTS_INVALID", message);
    }
}
