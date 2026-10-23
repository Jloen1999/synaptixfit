package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** La tarea está bloqueada hasta cumplir sus dependencias. */
public class MilestoneLockedException extends BusinessRuleException {

    public MilestoneLockedException(UUID id) {
        super("MILESTONE_LOCKED", "milestone " + id + " is locked by its dependencies");
    }
}
