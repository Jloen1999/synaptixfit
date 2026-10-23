package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** El nuevo orden debe incluir todas las tareas del reto una sola vez. */
public class InvalidMilestoneOrderException extends BusinessRuleException {

    public InvalidMilestoneOrderException() {
        super("MILESTONE_ORDER_INVALID", "the order must list every milestone of the challenge exactly once");
    }
}
