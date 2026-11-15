package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;
import com.synaptixfit.domain.model.training.RoutineShareLink;

/** La rutina ya tiene el máximo de enlaces vigentes: hay que dejar de compartirla para crear otro (ADR 0043). */
public class RoutineShareLinkLimitException extends BusinessRuleException {

    public RoutineShareLinkLimitException() {
        super("ROUTINE_SHARE_LINK_LIMIT", "a routine can have up to " + RoutineShareLink.MAX_ACTIVE_PER_ROUTINE
                + " active share links");
    }
}
