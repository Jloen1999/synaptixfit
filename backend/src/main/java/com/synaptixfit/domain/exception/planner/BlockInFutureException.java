package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Un bloque no se marca como hecho antes de empezar (evita sumar XP y horas por adelantado). */
public class BlockInFutureException extends BusinessRuleException {

    public BlockInFutureException() {
        super("BLOCK_IN_FUTURE", "A block cannot be completed before it starts");
    }
}
