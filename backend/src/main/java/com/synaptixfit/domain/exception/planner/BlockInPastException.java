package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No se crean ni se mueven bloques a una fecha u hora pasada. */
public class BlockInPastException extends BusinessRuleException {

    public BlockInPastException() {
        super("BLOCK_IN_PAST", "Blocks cannot be created or moved into the past");
    }
}
