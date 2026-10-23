package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Los bloques fijos (clases) y los hitos inamovibles no se mueven ni se redimensionan. */
public class BlockLockedException extends BusinessRuleException {

    public BlockLockedException() {
        super("BLOCK_LOCKED", "Fixed or immovable blocks cannot be moved or resized");
    }
}
