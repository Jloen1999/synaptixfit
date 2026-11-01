package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** El bloque vinculado a un reto (o a una de sus tareas) cae fuera del periodo de ese reto (ADR 0028). */
public class BlockOutsideChallengePeriodException extends BusinessRuleException {

    public BlockOutsideChallengePeriodException(UUID id) {
        super("BLOCK_OUTSIDE_CHALLENGE_PERIOD", "block outside the period of challenge " + id);
    }
}
